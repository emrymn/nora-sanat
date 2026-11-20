#!/bin/bash
# Nora Sanat — Mac'te bir kerelik kurulum.
# Xcode'a eklediğin Apple hesabının Team ID'sini bulur ve Config/Local.xcconfig'e yazar.
# Kullanım:  ./kur.sh            (kendisi bulur)
#            ./kur.sh ABCDE12345 (Team ID'yi elle ver)
set -uo pipefail
cd "$(dirname "$0")"

HEDEF="Config/Local.xcconfig"
TAKIM="${1:-}"

if [ -z "$TAKIM" ]; then
  # Xcode → Settings → Accounts'a eklenen hesapların takımları
  TAKIM=$(defaults read com.apple.dt.Xcode 2>/dev/null \
    | grep -Eo 'teamID = "?[A-Z0-9]{10}' | grep -Eo '[A-Z0-9]{10}$' | head -1)
fi

if [ -z "$TAKIM" ]; then
  # Anahtar zincirindeki "Apple Development" sertifikasından
  TAKIM=$(security find-certificate -c "Apple Development" -p 2>/dev/null \
    | openssl x509 -noout -subject 2>/dev/null \
    | grep -Eo 'OU ?= ?[A-Z0-9]{10}' | grep -Eo '[A-Z0-9]{10}$' | head -1)
fi

if [ -z "$TAKIM" ]; then
  echo "Team ID bulunamadı."
  echo "1) Xcode → Settings → Accounts → + → Apple ID ile giriş yap."
  echo "2) Sonra bu betiği tekrar çalıştır: ./kur.sh"
  echo "   (Team ID'yi biliyorsan: ./kur.sh ABCDE12345)"
  exit 1
fi

KUCUK=$(echo "$TAKIM" | tr '[:upper:]' '[:lower:]')
cat > "$HEDEF" <<EOF
// ./kur.sh tarafından yazıldı. Git'e girmez.
DEVELOPMENT_TEAM = $TAKIM
PAKET_KIMLIGI = com.$KUCUK.norasanat
EOF

echo "Tamam: $HEDEF yazıldı (Team ID: $TAKIM)."
echo "Şimdi: open NoraSanat.xcodeproj  → iPhone'u seç → ▶"
