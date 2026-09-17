---
name: Supabase credential validation
description: Safe checks for Supabase URL and anon-key pairs
---

When a Supabase URL and anon JWT are supplied together, compare the URL
project ref with the JWT payload ref and check DNS reachability before changing
the app's project-mismatch validation. A typo in the hostname can look like an
app networking bug, while disabling the mismatch check can hide a genuinely
wrong project pairing.

**Why:** The supplied hostname and JWT ref differed by one character; the
hostname in the URL did not resolve, while the ref encoded by the JWT did.

**How to apply:** Keep the URL aligned with the JWT ref and confirm the
Supabase endpoint resolves before claiming the socket failure is fixed. Do not
print keys or tokens during these checks.