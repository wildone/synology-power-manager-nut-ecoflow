## Step-by-Step Instructions (based on DSM 7.x)

> ⚠️ **Please back up relevant files before proceeding. Familiarity with SSH is recommended. The paths below are based on default installation locations.**

Source Docs: https://manuals.ecoflow.com/eu/product/power-manager?lang=en_US&source=desktop
Insparation: https://www.sandcomp.com/blog/en/2025/06/22/using-ecoflow-river-3-plus-as-a-ups-how-to-configure-synology-nas/
### 1. Install the Power Manager Package

Download and install from the EcoFlow official site:  
[https://www.ecoflow.com/us/support/download/index](https://www.ecoflow.com/us/support/download/index)

### 2. Modify `run.sh`

Path:  
```
vi /volume1/@appstore/PowerManagerNUT/usr/local/bin/nas/run.sh
```

**Change this line:**
```
output=$(sudo $BASE_DIR/bin/upsc nutdev1@127.0.0.1:3496 2>&1)
```

**To:**
```
output=$(sudo $BASE_DIR/bin/upsc ups@127.0.0.1:3493 2>&1)
```

### 3. Modify `upsd.conf`

Path:  
```
vi /volume1/@appstore/PowerManagerNUT/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/etc/upsd.conf
```

**Change this line:**
```
LISTEN 0.0.0.0 3496
```

**To:**
```
LISTEN 0.0.0.0 3493
```

### 4. Modify `ups.conf`

Path: 
```
vi /volume1/@appstore/PowerManagerNUT/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/etc/ups.conf
```

**Change this line:**
```
[nutdev1]
```
**To:**
```
[ups]
```

Comment out:
```
   usb_hid_ep_in = 1
   usb_hid_ep_out = 1
```

And add:
```
    vendorid = 3746
    productid = ffff
```

Final result:
```
[ups]
    driver = usbhid-ups
    port = auto
    vendorid = 3746
    productid = ffff
#   usb_hid_ep_in = 1
#   usb_hid_ep_out = 1
    pollfreq = 1
    ignorelb
    override.battery.runtime.low = -1
```

### 5. Modify `upsmon.conf`

```
vi /volume1/@appstore/PowerManagerNUT/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/etc/upsmon.conf
```

Comment out this line: 
```
MONITOR nutdev1@127.0.0.1:3496 1 Ecoflow Ecoflow primary
```
Add:
```
MONITOR ups@127.0.0.1:3493 1 ups synology master
```

### 6. Modify `eco_shutdown.sh`

Path:  
```
vi /volume1/@appstore/PowerManagerNUT/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/script/eco_shutdown.sh
```

**Change this line:**
```
status=$(/var/packages/PowerManagerNUT/target/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/bin/upsc nutdev1@localhost:3496 ups.status 2>/dev/null)
```
**To:**
```
status=$(/var/packages/PowerManagerNUT/target/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/bin/upsc ups@localhost:3493 ups.status 2>/dev/null)
```

### 7. Add user

Path:
```
vi /volume1/@appstore/PowerManagerNUT/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/etc/upsd.users
```
Add:
```
[ups]
    password = synology
    upsmon master
    actions = SET
    instcmds = ALL
```

### 7. Restart the Power Manager Service

```
synopkg stop PowerManagerNUT
synopkg start PowerManagerNUT
```

### 8. Create a simplified run script

Here’s a clean `run.sh` (same layout, full verbose logging, fixed logic). Backup the old file as `run.sh.old` and make a new file `run.sh`, use this content and do `chmod 775 run.sh`.

Path:  
```
cp /volume1/@appstore/PowerManagerNUT/usr/local/bin/nas/run.sh /volume1/@appstore/PowerManagerNUT/usr/local/bin/nas/run.sh.old.1
echo "">/volume1/@appstore/PowerManagerNUT/usr/local/bin/nas/run.sh
vi /volume1/@appstore/PowerManagerNUT/usr/local/bin/nas/run.sh
```


```bash
#!/bin/bash

# PowerManagerNUT run script (EcoFlow + Synology DS918+)
# - Uses packaged NUT under x86_64-pc-linux-gnu-nut-server
# - Exposes UPS as ups@127.0.0.1:3493
# - Intended to be called by start-stop-status / synopkg

LOG_DIR="/var/packages/PowerManagerNUT/target/var/log"
mkdir -p "$LOG_DIR"
exec >> "$LOG_DIR/run.sh.log" 2>&1
echo "===== run.sh start $(date) ====="

log()  { echo "[INFO] $*"; }
err()  { echo "[ERROR] $*" >&2; }
die()  { err "$@"; exit 1; }

has_proc() {
    # $1: substring to look for in process list
    ps aux | grep "$1" | grep -v grep >/dev/null 2>&1
}

stop_proc() {
    # $1: substring (binary name)
    for pid in $(ps aux | grep "$1" | grep -v grep | awk '{print $2}'); do
        kill "$pid" 2>/dev/null || true
    done
}

# ---------------------------------------------------------------------
# Absolute base paths
# ---------------------------------------------------------------------
PKG_NAS_DIR="/var/packages/PowerManagerNUT/target/usr/local/bin/nas"
NUT_BASE="${PKG_NAS_DIR}/x86_64-pc-linux-gnu-nut-server"

[ -d "$PKG_NAS_DIR" ] || die "PKG_NAS_DIR not found: $PKG_NAS_DIR"
[ -d "$NUT_BASE" ]    || die "NUT_BASE not found: $NUT_BASE"

SETUP_ENV="${NUT_BASE}/script/setup_env.sh"
[ -f "$SETUP_ENV" ] || die "setup_env.sh missing: $SETUP_ENV"

cd "$PKG_NAS_DIR" || die "Failed to cd to $PKG_NAS_DIR"

# ---------------------------------------------------------------------
# Environment setup (udev rules + libs)
# ---------------------------------------------------------------------
log "Running setup_env.sh..."
if ! output="$(sh "$SETUP_ENV" 2>&1)"; then
    echo "$output"
    die "Environment setup failed"
fi

echo "$output" | grep -qi "Installation completed successfully" || \
    log "Environment setup completed (no standard phrase, continuing)"

log "Environment setup OK"
echo

# ---------------------------------------------------------------------
# NUT environment paths
# ---------------------------------------------------------------------
export NUT_CONFPATH="$NUT_BASE/etc"
export NUT_STATEPATH="$NUT_BASE/var/state/ups"
export NUT_UPSDRVPATH="$NUT_BASE/bin"
export NUT_UPSHOSTSDIR="$NUT_BASE/etc"
export NUT_POWERDOWNFLAG="/etc/killpower"

mkdir -p "$NUT_STATEPATH"

log "Using NUT_CONFPATH=$NUT_CONFPATH"
log "Using NUT_UPSDRVPATH=$NUT_UPSDRVPATH"
echo

# ---------------------------------------------------------------------
# Stop any existing NUT daemons
# ---------------------------------------------------------------------
log "Stopping existing NUT processes (if any)..."
stop_proc "usbhid-ups"
stop_proc "upsd"
stop_proc "upsmon"
echo

# ---------------------------------------------------------------------
# Scan for EcoFlow UPS
# ---------------------------------------------------------------------
NUT_SCANNER="$NUT_BASE/bin/nut-scanner"
[ -x "$NUT_SCANNER" ] || die "nut-scanner not found: $NUT_SCANNER"

log "Scanning for EcoFlow UPS..."
scan_output="$("$NUT_SCANNER" -U 2>&1)"
echo "$scan_output"

case "$scan_output" in
    *'vendor = "EcoFlow"'*)
        log "EcoFlow UPS detected"
        ;;
    *)
        die "EcoFlow UPS not found; check USB connection and power"
        ;;
esac
echo

# ---------------------------------------------------------------------
# Start driver (usbhid-ups) via upsdrvctl
# ---------------------------------------------------------------------
UPSDRVCTL="$NUT_BASE/sbin/upsdrvctl"
[ -x "$UPSDRVCTL" ] || die "upsdrvctl not found: $UPSDRVCTL"

log "Starting NUT driver (upsdrvctl)..."
drv_output="$("$UPSDRVCTL" -u root start ups 2>&1)"
echo "$drv_output"

# If driver clearly reports failure, abort
if echo "$drv_output" | grep -Eiq "Driver failed|exit status"; then
    die "upsdrvctl reported failure. Check USB connection and $NUT_CONFPATH/ups.conf"
fi

# Relaxed sanity check: see if usbhid-ups appears (but don't hard-fail here)
sleep 2
if has_proc "usbhid-ups"; then
    log "Driver appears to be running"
else
    err "usbhid-ups process not detected; will rely on upsd/upsc check"
fi
echo

# ---------------------------------------------------------------------
# Start upsd on 3493
# ---------------------------------------------------------------------
UPSD="$NUT_BASE/sbin/upsd"
[ -x "$UPSD" ] || die "upsd not found: $UPSD"

log "Starting upsd..."
upsd_output="$("$UPSD" -u root 2>&1)"
echo "$upsd_output"

sleep 1
if ! netstat -tlnp 2>/dev/null | grep -q "3493"; then
    die "upsd did not start on port 3493. Check $NUT_CONFPATH/upsd.conf"
fi

log "upsd started successfully on port 3493"
echo

# ---------------------------------------------------------------------
# Validate with upsc
# ---------------------------------------------------------------------
UPSC="$NUT_BASE/bin/upsc"
[ -x "$UPSC" ] || die "upsc not found: $UPSC"

log "Validating UPS status via upsc ups@127.0.0.1:3493..."
upsc_output="$("$UPSC" ups@127.0.0.1:3493 2>&1)" || die "upsc failed: $upsc_output"
echo "$upsc_output"

echo "$upsc_output" | grep -q "ups.status" || die "upsc did not return ups.status; NUT not healthy"

log "upsc OK — UPS is reachable as ups@127.0.0.1:3493"
echo

# ---------------------------------------------------------------------
# Start upsmon
# ---------------------------------------------------------------------
UPSMON="$NUT_BASE/sbin/upsmon"
[ -x "$UPSMON" ] || die "upsmon not found: $UPSMON"

log "Starting upsmon..."
upsmon_output="$("$UPSMON" 2>&1)"
echo "$upsmon_output"

sleep 1
if ! has_proc "upsmon"; then
    die "upsmon did not stay running. Check $NUT_CONFPATH/upsmon.conf"
fi

log "upsmon started successfully"
echo

log "EcoFlow UPS is running via NUT as ups@127.0.0.1:3493"
log "run.sh completed successfully."
exit 0
```

### 9. Add start-stop-status script

Path:
```
cp /var/packages/PowerManagerNUT/scripts/start-stop-status /var/packages/PowerManagerNUT/scripts/start-stop-status.old.1
echo "">/var/packages/PowerManagerNUT/scripts/start-stop-status
vi /var/packages/PowerManagerNUT/scripts/start-stop-status
```

```bash
#!/bin/sh
RUN_SH="/var/packages/PowerManagerNUT/target/usr/local/bin/nas/run.sh"
LOG_FILE="/var/packages/PowerManagerNUT/target/var/log/run.sh.log"

timestamp(){ date +"%a %b %d %H:%M:%S %Z %Y"; }

case "$1" in
  start)
    echo "===== run.sh start $(timestamp) =====" >>"$LOG_FILE"
    /bin/bash "$RUN_SH"
    ;;
  stop)
    echo "===== run.sh stop $(timestamp) =====" >>"$LOG_FILE"
    echo "[INFO] PowerManagerNUT stopping (DSM stop)..." >>"$LOG_FILE"
    for p in usbhid-ups upsd upsmon; do
      pkill -f "$p" 2>/dev/null || true
    done
    sleep 1
    if ps | grep -Eq "usbhid-ups|upsd|upsmon"; then
      echo "[WARN] Some NUT processes still appear to be running after stop" >>"$LOG_FILE"
    else
      echo "[INFO] All NUT processes stopped cleanly" >>"$LOG_FILE"
    fi
    ;;
  status)
    if ps | grep -Eq "usbhid-ups|upsd|upsmon"; then
      echo "running"
      echo "===== run.sh status $(timestamp) =====" >>"$LOG_FILE"
      echo "[INFO] PowerManagerNUT status: running" >>"$LOG_FILE"
    else
      echo "stopped"
      echo "===== run.sh status $(timestamp) =====" >>"$LOG_FILE"
      echo "[INFO] PowerManagerNUT status: stopped" >>"$LOG_FILE"
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|status}"
    exit 1
    ;;
esac
exit 0

```

### 10. Restart Power Manager Service again

```
echo "">/var/packages/PowerManagerNUT/target/var/log/run.sh.log

synopkg stop PowerManagerNUT
cat /var/packages/PowerManagerNUT/target/var/log/run.sh.log
synopkg start PowerManagerNUT
cat /var/packages/PowerManagerNUT/target/var/log/run.sh.log
```


### 11. Set Synology to Use the UPS Server

1. Open **Control Panel** → **Hardware & Power** → **UPS** tab.
2. Tick **Enable UPS support**.
3. Under **UPS Type**, select **Synology UPS Server** (or **Synology UPS Support** depending on DSM version)    
4. In the **Network UPS Server IP** field, enter **your NAS’s own IP address** (e.g. `192.168.1.100`).
5. Click **Apply** or **Save** to confirm.
6. You can now click **Device Information** to confirm that the UPS status is visible and matches the `upsc` output (e.g. `OL` for on-line power).


### 12. Configure Remote UPS Access in Power Manager

To enable **remote mode** in the **Power Manager** app:

1. Open the **Power Manager** app on the remote NAS. 
2. Click the **Edit** button next to the connection mode.
3. Switch to **Remote Mode**.
4. Enter the following parameters:
    - **UPS device name:** `ups`
    - **NAS system IP address:** your **main NAS’s IP address**
    - **Port:** `3493`
    - **Account:** `ups`
    - **Password:** `synology`
5. Click **Confirm** to establish the connection.
6. Once connected successfully, **Power Manager** will automatically redirect to its homepage and begin monitoring the UPS status from your main NAS.