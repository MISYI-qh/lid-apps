#!/usr/bin/env bash
# Menjalankan perintah; bila gagal, 40 baris terakhir log dikirim sebagai anotasi GitHub.
"$@" 2>&1 | tee /tmp/step.log
rc=${PIPESTATUS[0]}
if [ "$rc" -ne 0 ]; then
  python3 - <<'P'
t=open('/tmp/step.log',errors='replace').read().splitlines()[-40:]
m='\n'.join(t)[-3500:]
print('::error title=GAGAL::'+m.replace('%','%25').replace('\r','').replace('\n','%0A'))
P
fi
exit $rc
