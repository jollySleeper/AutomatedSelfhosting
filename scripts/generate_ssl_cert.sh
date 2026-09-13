#!/bin/bash

# SSL Certificate Generation Script
# Based on: https://akashrajpurohit.com/blog/https-with-selfsigned-certificates-for-your-homelab-services/
#
# Usage:
#   ./generate_ssl_cert.sh [domain1] [domain2] ...
#   Example: ./generate_ssl_cert.sh aevion.lan *.aevion.lan
#
# This script will:
# 1. Create a CA (Certificate Authority) if it doesn't exist
# 2. Generate SSL certificates for the specified domains
# 3. Copy certificates to nginx directory

set -euo pipefail

# Configuration
CERTS_DIR="$HOME/certs"
CA_KEY="$CERTS_DIR/ca-key.pem"
CA_CERT="$CERTS_DIR/ca.pem"
CA_SERIAL="$CERTS_DIR/ca.srl"
SERVICE_KEY="$CERTS_DIR/cert-key.pem"
SERVICE_CERT="$CERTS_DIR/cert.pem"
SERVICE_CSR="$CERTS_DIR/cert.csr"
EXTFILE="$CERTS_DIR/extfile.cnf"
FULLCHAIN="$CERTS_DIR/fullchain.pem"

# Certificate validity (10 years)
CERT_VALIDITY=3650

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if domains were provided
if [ $# -eq 0 ]; then
    log_error "No domains specified!"
    echo "Usage: $0 <domain1> [domain2] [domain3] ..."
    echo "Example: $0 aevion.lan *.aevion.lan"
    exit 1
fi

# Create certs directory if it doesn't exist
mkdir -p "$CERTS_DIR"
log_info "Using certificate directory: $CERTS_DIR"

# Function to create CA
create_ca() {
    if [ -f "$CA_CERT" ]; then
        log_info "CA certificate already exists, skipping CA creation"
        return
    fi

    log_info "Creating Certificate Authority (CA)..."

    # Generate CA private key
    log_info "Generating CA private key..."
    openssl genrsa -aes256 -out "$CA_KEY" 4096

    # Generate CA certificate
    log_info "Generating CA certificate..."
    openssl req -new -x509 -sha256 -days "$CERT_VALIDITY" \
        -key "$CA_KEY" -out "$CA_CERT" \
        -subj "/C=IN/O=SelfHost/OU=IT/CN=SelfHost CA"

    log_success "CA created successfully"
}

# Function to create service certificates
create_service_cert() {
    local domains=("$@")

    log_info "Creating service certificates for domains: ${domains[*]}"

    # Generate service private key
    log_info "Generating service private key..."
    openssl genrsa -out "$SERVICE_KEY" 4096

    # Create certificate signing request
    log_info "Creating certificate signing request..."
    openssl req -subj "/CN=${domains[0]}" -sha256 -new \
        -key "$SERVICE_KEY" -out "$SERVICE_CSR"

    # Create extfile with subject alternative names
    log_info "Creating certificate extensions file..."
    {
        echo "[ v3_req ]"
        echo "subjectAltName = $(printf "DNS:%s," "${domains[@]}" | sed 's/,$//')"
    } > "$EXTFILE"

        # Sign the certificate with CA
    log_info "Signing certificate with CA..."
    echo "Enter CA private key passphrase:"
    openssl x509 -req -sha256 -days "$CERT_VALIDITY" \
        -in "$SERVICE_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" \
        -out "$SERVICE_CERT" -extfile "$EXTFILE" -extensions v3_req -CAcreateserial

    # Create fullchain (certificate + CA)
    log_info "Creating certificate chain..."
    cat "$SERVICE_CERT" "$CA_CERT" > "$FULLCHAIN"

    log_success "Service certificates created successfully"
}

# Function to copy certificates to nginx
copy_to_nginx() {
    local nginx_certs_dir="$HOME/selfhost/apps/nginx/configs/certs"

    log_info "Copying certificates to nginx directory: $nginx_certs_dir"

    mkdir -p "$nginx_certs_dir"

    cp "$FULLCHAIN" "$nginx_certs_dir/"
    cp "$SERVICE_KEY" "$nginx_certs_dir/"

    # Set appropriate permissions
    chmod 644 "$nginx_certs_dir/fullchain.pem"
    chmod 600 "$nginx_certs_dir/cert-key.pem"

    log_success "Certificates copied to nginx"
}

# Function to verify certificates
verify_certificates() {
    log_info "Verifying certificates..."

    # Check certificate validity
    local expiry_date
    expiry_date=$(openssl x509 -in "$FULLCHAIN" -enddate -noout | cut -d= -f2)
    log_info "Certificate expires: $expiry_date"

    # Verify certificate chain
    if openssl verify -CAfile "$CA_CERT" "$FULLCHAIN" >/dev/null 2>&1; then
        log_success "Certificate chain verification passed"
    else
        log_error "Certificate chain verification failed"
        return 1
    fi

    # Show certificate details
    log_info "Certificate details:"
    openssl x509 -in "$FULLCHAIN" -subject -noout
    openssl x509 -in "$FULLCHAIN" -dates -noout
}

# Main execution
main() {
    log_info "SSL Certificate Generation Script"
    log_info "=================================="

    # Create CA
    create_ca

    # Create service certificates
    create_service_cert "$@"

    # Copy to nginx
    copy_to_nginx

    # Verify
    verify_certificates

    log_success "Certificate generation completed!"
    echo ""
    log_info "Next steps:"
    echo "1. Copy ca.pem to your client machines"
    echo "2. Add ca.pem to trusted certificates (see tutorial)"
    echo "3. Restart nginx: systemctl --user restart nginx"
    echo ""
    log_info "Certificate files created:"
    echo "  CA Certificate: $CA_CERT"
    echo "  Service Certificate: $SERVICE_CERT"
    echo "  Full Chain: $FULLCHAIN"
    echo "  Private Key: $SERVICE_KEY"
}

# Run main function with all arguments
main "$@"
