import sys
import os
import zipfile
from cryptography.fernet import Fernet

def loadKey():
    if getattr(sys, 'frozen', False):
        keyPath = os.path.join(sys._MEIPASS, "secretKey.key")
    else:
        keyPath = "secretKey.key"
    return open(keyPath, "rb").read()

def decryptFiles():
    try:
        key = loadKey()
        fernet = Fernet(key)
       
        currentDirectory = os.getcwd()
        zipFiles = [f for f in os.listdir(currentDirectory) if f.endswith('.zip')]

        zipFilename = zipFiles[0]

        with open(zipFilename, "rb") as f:
            encryptedZipData = f.read()

        decryptedZipData = fernet.decrypt(encryptedZipData)

        decryptedZipFilename = "decrypted_" + os.path.basename(zipFilename)
        with open(decryptedZipFilename, "wb") as f:
            f.write(decryptedZipData)

        folder_name = os.path.splitext(zipFilename)[0]
        folder_path = os.path.join(currentDirectory, folder_name)

        if not os.path.exists(folder_path):
            os.makedirs(folder_path)

        with zipfile.ZipFile(decryptedZipFilename, 'r') as zipf:
            zipf.extractall(folder_path)

        os.remove(decryptedZipFilename)
        os.remove(zipFilename)
    except Exception as e:
        print(f"Error during decryption and extraction: {e}")

if __name__ == "__main__":

    decryptFiles()

    
