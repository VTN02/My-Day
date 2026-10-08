# MyDay — Security & Privacy Architecture

## Core Security Tenets
1. **Zero Mandatory Cloud Dependencies**: The MVP stores all sensitive personal, note, task, and financial data strictly on the local device.
2. **Encrypted Storage**: Sensitive keys and tokens are stored in platform secure storage (Android Keystore / EncryptedSharedPreferences).
3. **No Hardcoded Credentials**: API secrets, private keys, and service role keys are strictly prohibited in client bundles.
4. **Least Privilege Principle**: Administrative users in future cloud milestones will not have arbitrary access to unencrypted personal user transactions or notes.
5. **Integer Currency Integrity**: Financial math avoids IEEE 754 floating-point rounding bugs by computing all balances in minor currency units (integer cents).
