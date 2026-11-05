
# Quality Policy



1. Test skipping is strictly forbidden.

2. Coverage threshold is 40%. Lowering it requires written justification.

3. SAST (bandit) and linter (ruff) exceptions must be documented.

4. All changes must pass `make verify` before merge.




## Documented analyzer exceptions

- B105 in app/auth.py: the string "bearer" is the OAuth2 token type constant, not a password. Suppressed via nosec with written justification.




## Documented analyzer exceptions

- B105 in app/auth.py: the string "bearer" is the OAuth2 token type constant, not a password. Suppressed via nosec with written justification.

