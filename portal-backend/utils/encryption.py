"""
Encryption Utilities
Encrypt/decrypt sensitive data (service principal secrets, passwords)
"""

from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.backends import default_backend
import base64
import os

from config import settings

# Derive key from SECRET_KEY
def _get_fernet_key() -> bytes:
    """Generate Fernet key from SECRET_KEY"""
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=b'caflz-salt-change-in-prod',  # TODO: Use dynamic salt
        iterations=100000,
        backend=default_backend()
    )
    key = base64.urlsafe_b64encode(kdf.derive(settings.SECRET_KEY.encode()))
    return key

# Initialize Fernet cipher
_fernet = Fernet(_get_fernet_key())

def encrypt_value(plaintext: str) -> str:
    """Encrypt string value"""
    if not plaintext:
        return ""
    
    encrypted = _fernet.encrypt(plaintext.encode())
    return base64.urlsafe_b64encode(encrypted).decode()

def decrypt_value(ciphertext: str) -> str:
    """Decrypt string value"""
    if not ciphertext:
        return ""
    
    try:
        decoded = base64.urlsafe_b64decode(ciphertext.encode())
        decrypted = _fernet.decrypt(decoded)
        return decrypted.decode()
    except Exception as e:
        raise ValueError(f"Decryption failed: {str(e)}")