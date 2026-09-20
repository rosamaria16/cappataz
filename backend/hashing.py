from pwdlib import PasswordHash
from db_config import required_env

PASSWORD_PEPPER = required_env("PASSWORD_PEPPER")
PASSWORD_HASH = PasswordHash.recommended()
dummy_hash = PASSWORD_HASH.hash(f"dummypassword{PASSWORD_PEPPER}") #dummy hash to prevent timing attacks

#hashing
def verify_password(plain_password, hashed_password):
    return PASSWORD_HASH.verify(f"{plain_password}{PASSWORD_PEPPER}", hashed_password)

def get_password_hash(password):
    return PASSWORD_HASH.hash(f"{password}{PASSWORD_PEPPER}")
