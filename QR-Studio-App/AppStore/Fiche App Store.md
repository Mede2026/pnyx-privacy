# QR Studio — fiche App Store

Un seul identifiant pour iPhone, iPad, Mac et Apple Watch : `app.qrstudio` (achat universel, une seule fiche).

## Informations de l'app

| Champ | Valeur |
|---|---|
| Nom (30 max) | QR Studio |
| Sous-titre (30 max, 29 utilisés) | Scanner et créer des codes QR |
| Catégorie principale | Utilitaires |
| Catégorie secondaire | Productivité |
| Prix | Gratuit, aucun achat intégré |
| Langue principale | Français |
| Identifiant de lot | app.qrstudio |
| SKU | QRSTUDIO-001 |

## Texte promotionnel (170 max, 151 utilisés)

Scannez, créez et personnalisez vos codes QR et codes-barres. Gratuit, sans publicité, sans compte : tout reste sur vos appareils et dans votre iCloud.

## Mots-clés (100 max, 100 utilisés)

```
qr,code,scanner,lecteur,code-barres,générateur,wifi,fidélité,ean,vcard,menu,inventaire,lot,étiquette
```

## Description

QR Studio lit et crée tous les codes du quotidien, sur iPhone, iPad, Mac et Apple Watch. Entièrement gratuit : aucun abonnement, aucune publicité, aucun compte.

SCANNER SANS APPUYER
• Pointez, c'est tout : le code est lu dès qu'il entre dans le champ, sans bouton ni photo.
• Tous les formats : QR, Aztec, PDF417, Data Matrix, EAN, UPC, Code 128, Code 39 et plus.
• Mode lot pour les inventaires, avec quantités, notes et export CSV.
• Lecture depuis une photo, le presse-papier ou une capture d'écran.

DES ACTIONS QUI COMPRENNENT LE CONTENU
• Wi-Fi : connexion en un geste.
• Contact, événement, courriel, SMS, lieu : ajoutés au bon endroit.
• Produit : nom du produit, pays GS1, recherche sur les sites de votre choix.
• Liens : domaine affiché en grand, alertes contre les caractères trompeurs et les liens raccourcis, vérification Google Safe Browsing en option.
• Traduction du texte scanné, sur l'appareil.

CRÉER DES CODES À VOTRE IMAGE
• 13 types de contenu : lien, Wi-Fi, carte de visite, événement, lieu, cryptomonnaie…
• Couleurs, dégradés, formes des modules et des yeux, logo, cadre et légende.
• Chaque code est relu avant d'être proposé : un indicateur vous dit s'il est lisible.
• Export PNG, JPEG, PDF vectoriel et SVG, jusqu'à 2048 pixels.

TOUT RETROUVER
• Historique groupé par jour, dossiers, favoris, recherche et filtres.
• Recherche en langage naturel et libellés suggérés avec Apple Intelligence.
• Synchronisation iCloud entre vos appareils, sauvegarde en fichier.
• Carte des lieux de scan, si vous l'activez.

PARTOUT DANS VOTRE APPAREIL
• Siri et Raccourcis : « Montre mon code Wi-Fi dans QR Studio ».
• Widgets, Spotlight, Intelligence visuelle, extension de partage.
• Apple Watch : votre carte de fidélité au poignet, même sans l'iPhone.
• Mac : votre iPhone devient un lecteur de codes-barres sans fil qui tape dans vos tableurs.

VOTRE VIE PRIVÉE
Aucune donnée n'est collectée. Vos codes restent sur vos appareils et dans votre iCloud privé.

## Adresses

| Champ | Adresse |
|---|---|
| URL marketing | https://mede2026.github.io/pnyx-privacy/qr-studio/ |
| URL d'assistance | https://mede2026.github.io/pnyx-privacy/qr-studio/support.html |
| Politique de confidentialité | https://mede2026.github.io/pnyx-privacy/qr-studio/privacy-policy.html |

## Confidentialité (App Store Connect › Confidentialité de l'app)

- Pratiques de collecte : **Données non collectées**.
- URL de la politique de confidentialité : https://mede2026.github.io/pnyx-privacy/qr-studio/privacy-policy.html
- Les manifestes `PrivacyInfo.xcprivacy` sont inclus dans l'app, les extensions, la montre et QRCore.

## Classification par âge

Répondre « Aucun » partout. « Accès web illimité » : **Non**. L'app n'est pas un navigateur. Elle affiche toujours le domaine avant d'ouvrir un lien (feuille de résultat, ou bannière de 1,5 seconde avec Annuler), et les liens s'ouvrent dans Safari intégré. Résultat attendu : **4+**.

## Chiffrement

`ITSAppUsesNonExemptEncryption = NO` est déclaré : l'app n'utilise que le chiffrement standard du système (HTTPS, TLS du framework Network). Aucune documentation d'exportation n'est requise.

## Notes pour l'équipe de revue

> QR Studio ne demande aucun compte.
> Le scanner démarre sur l'écran d'accueil ; pour tester sans code imprimé, utilisez « Scanner une photo » avec une image contenant un QR.
> Google Safe Browsing est désactivé par défaut (Réglages › Réseau). Une fois activé, le lien de test https://testsafebrowsing.appspot.com/s/phishing.html déclenche l'écran d'avertissement.
> L'envoi des scans vers le Mac demande deux appareils sur le même réseau ; l'appairage se fait en scannant le QR affiché par l'app Mac (Réglages › iPhone).
> Le mode webhook est désactivé par défaut et n'envoie rien tant que l'utilisateur n'a pas saisi sa propre adresse.

## Captures

| Appareil | Dossier | Taille |
|---|---|---|
| iPhone 6,9 pouces | `Captures/iPhone 6,9 pouces` | 1320 × 2868 (5 captures) |
| iPad 13 pouces | `Captures/iPad 13 pouces` | 2064 × 2752 (2 captures) |
| Apple Watch | `Captures/Apple Watch 46 mm` | 416 × 496 (2 captures) |
| Mac | à faire | 2880 × 1800 conseillé : fenêtre principale avec un code stylisé, puis le générateur |

Les captures iPhone et iPad ont été prises dans le simulateur avec les données de démonstration (`-QRStudioDemo`, build Debug seulement).

## TestFlight, étape par étape

1. App Store Connect › Apps › « + » › Nouvelle app : plateformes iOS et macOS, nom QR Studio, langue Français, identifiant de lot `app.qrstudio`, SKU `QRSTUDIO-001`.
2. Dans Xcode : Product › Archive (schéma QRStudio, destination « Any iOS Device »), puis Distribute App › App Store Connect › Upload. Même chose pour le schéma QRStudioMac.
3. Dans App Store Connect › TestFlight : ajoutez-vous comme testeur interne ; la build arrive après le traitement (10 à 30 minutes).
