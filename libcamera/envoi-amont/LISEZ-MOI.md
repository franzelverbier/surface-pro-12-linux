# Envoi du helper `ov02c10` à libcamera — prêt, NON ENVOYÉ

## État

Patch préparé, vérifié, essai d'envoi à blanc concluant. **Rien n'a été transmis** :
l'envoi à une liste de diffusion publique est une publication, elle attend un « oui »
explicite de FR.

## Ce qui a été fait

- Commit créé sur le tag `v0.7.2` de libcamera, **ne contenant que notre fichier**
  (le correctif Arch pour Python 3.14 a été écarté du commit).
- Message rédigé sur le modèle du commit amont `0a1cff8bb` (« add ov08x40 »), qui suit
  exactement le même raisonnement : encodage du gain lu dans le pilote noyau, piédestal
  de niveau de noir, matériel d'essai.
- `utils/checkstyle.py` : **aucun écart de style**. Le seul signalement est
  « Missing reuse to run LicenseChecker », c'est-à-dire l'absence de l'outil `reuse`,
  pas un défaut du patch.
- `git send-email --dry-run` vers `libcamera-devel@lists.libcamera.org` : `Result: OK`.

## Ce qui deviendra public

| Donnée | Pourquoi |
|---|---|
| `François Roux <info@humanlearning.ch>` | exigé par le `Signed-off-by` (DCO) — seul FR peut le signer |
| Modèle et SoC (Surface Pro 12, X1P42100) | la section « Tested on » attendue par le projet |

Aucun secret technique : ni adresse IP, ni SSID, ni identifiant, ni jeton.

## La commande, si FR valide

```bash
cd <arbre libcamera>
git send-email --to=libcamera-devel@lists.libcamera.org \
               --no-chain-reply-to --suppress-cc=all \
               0001-ipa-libipa-camera_sensor_helper-add-ov02c10.patch
```

Le SMTP Infomaniak est déjà configuré dans le `.gitconfig` global.
