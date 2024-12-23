#!/usr/bin/env python3
import bcrypt

def generate_password_hash(password):
    salt = bcrypt.gensalt()
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed_password.decode('utf-8')

if __name__ == "__main__":
    import sys
    username = sys.argv[1]
    password = sys.argv[2]
    hashed_password = generate_password_hash(password)
    print(f"{username}:{hashed_password}")