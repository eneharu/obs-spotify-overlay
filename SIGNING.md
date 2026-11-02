# Signing

The released DLL is currently **not code-signed**, which is why Windows 11 with
Smart App Control turned on blocks it. See the "Smart App Control" section in
[README.md](README.md) for the user-facing explanation.

## What is required

Smart App Control only accepts signatures from a certificate authority in the
[Microsoft Trusted Root Program](https://learn.microsoft.com/security/trusted-root/participants-list).
Self-signed certificates and certificates trusted only on one computer do not
work for public distribution.

Affordable options for an open-source project:

| Option | Cost | Notes |
| --- | --- | --- |
| [SignPath Foundation](https://signpath.org/) | Free | Requires an OSI-approved license, a public repository and a CI build. Certificate is issued to SignPath Foundation. |
| [Certum Open Source Code Signing](https://www.certum.eu/en/code-signing-certificates/open-source-code-signing/) | from €49/year | Cloud signing, no card reader. Certum is a Polish CA in the Trusted Root Program. |
| Standard OV code signing (any CA) | from ~€150/year | Works the same for Smart App Control. |

An OV certificate is enough. EV certificates are not required by Smart App
Control and no longer give an instant SmartScreen reputation boost.

## Signing the DLL

1. Install the certificate (or start the CA's cloud signing app, for example
   SimplySign for Certum).
2. Run:

```powershell
.\tools\sign.ps1 -Certificate <thumbprint>
```

or, with a PFX file:

```powershell
.\tools\sign.ps1 -Certificate .\certificate.pfx -Password "<password>"
```

The script signs `spotify-overlay.dll` with SHA-256 and an RFC 3161 timestamp,
then prints the signature status. The timestamp keeps the signature valid after
the certificate expires.

## Verify

```powershell
Get-AuthenticodeSignature .\spotify-overlay.dll | Format-List Status, SignerCertificate
```

`Status` must be `Valid` and the signer must chain to a CA in the Trusted Root
Program. Then rebuild `SpotifyOverlay-OBS.zip` and publish a new release.

## After signing

- Put a signature check in the release checklist.
- Keep the timestamp enabled so old releases stay valid.
- Update the "Smart App Control" sections in both READMEs: the plugin now runs
  on PCs with Smart App Control turned on.
