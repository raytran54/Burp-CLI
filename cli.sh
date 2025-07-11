#!/bin/bash

##########################################
# Burp Suite Headless Launcher for macOS
# Improved version by ChatGPT
##########################################

JAVA_PATH="/usr/local/opt/openjdk@21/bin/java"
BURP_JAR="./burpsuite_pro_v2025.jar"
LOADER_JAR="./loader.jar"
PROJECT_FILE="./project/test.burp"
CONFIG_FILE="./user-config.json"

# Remove old project lock if stuck
rm -f "${PROJECT_FILE}.lock"

echo "🔍 Kiểm tra file..."

for f in "$JAVA_PATH" "$BURP_JAR" "$LOADER_JAR" "$CONFIG_FILE"; do
  if [ ! -f "$f" ]; then echo "❌ Thiếu file: $f"; exit 1; fi
done

# Optional: Remove old .burp file (uncomment nếu cần reset sạch)
# rm -f "$PROJECT_FILE"

echo "🚀 Khởi chạy Burp Suite Professional (headless)..."
"$JAVA_PATH" \
  --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
  --add-opens=java.base/java.lang=ALL-UNNAMED \
  --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
  --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
  --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
  -Djava.awt.headless=true \
  -Xmx2g \
  -javaagent:"$LOADER_JAR" \
  -jar "$BURP_JAR" \
  --project-file="$PROJECT_FILE" \
  --config-file="$CONFIG_FILE"

echo ""
echo "✅ Kết thúc. Mở GUI để kiểm tra crawl trong Target → Site Map."

