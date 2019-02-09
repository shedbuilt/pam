#!/bin/bash
declare -A SHED_PKG_LOCAL_OPTIONS=${SHED_PKG_OPTIONS_ASSOC}
# Configure
./configure --prefix=/usr                    \
            --sysconfdir=/etc                \
            --libdir=/usr/lib                \
            --disable-regenerate-docu        \
            --enable-securedir=/lib/security \
            --docdir="$SHED_PKG_DOCS_INSTALL_DIR" &&
# Build
make -j $SHED_NUM_JOBS &&
make DESTDIR="$SHED_FAKE_ROOT" install &&

# Place setuid bit on unix_checkpwd
chmod -v 4755 "${SHED_FAKE_ROOT}"/sbin/unix_chkpwd || exit 1

# Rearrange
for SHED_PKG_LOCAL_PAMLIB in pam pam_misc pamc
do
    mv -v "${SHED_FAKE_ROOT}"/usr/lib/lib${SHED_PKG_LOCAL_PAMLIB}.so.* "${SHED_FAKE_ROOT}"/lib &&
    ln -sfv ../../lib/$(readlink "${SHED_FAKE_ROOT}"/usr/lib/lib${SHED_PKG_LOCAL_PAMLIB}.so) "${SHED_FAKE_ROOT}"/usr/lib/lib${SHED_PKG_LOCAL_PAMLIB}.so || exit 1
done

# Install Defaults
install -v -Dm644 "${SHED_PKG_CONTRIB_DIR}/other" "${SHED_FAKE_ROOT}${SHED_PKG_DEFAULTS_INSTALL_DIR}/etc/pam.d/other" &&
install -v -m644 "${SHED_PKG_CONTRIB_DIR}/system-account" "${SHED_FAKE_ROOT}${SHED_PKG_DEFAULTS_INSTALL_DIR}/etc/pam.d" &&
install -v -m644 "${SHED_PKG_CONTRIB_DIR}/system-auth" "${SHED_FAKE_ROOT}${SHED_PKG_DEFAULTS_INSTALL_DIR}/etc/pam.d" &&
install -v -m644 "${SHED_PKG_CONTRIB_DIR}/system-password" "${SHED_FAKE_ROOT}${SHED_PKG_DEFAULTS_INSTALL_DIR}/etc/pam.d" || exit 1
if [ -n "${SHED_PKG_LOCAL_OPTIONS[bootstrap]}" ]; then
    install -v -m644 "${SHED_PKG_CONTRIB_DIR}/system-session-bootstrap" "${SHED_FAKE_ROOT}${SHED_PKG_DEFAULTS_INSTALL_DIR}/etc/pam.d" || exit 1
else
    install -v -m644 "${SHED_PKG_CONTRIB_DIR}/system-session-release" "${SHED_FAKE_ROOT}${SHED_PKG_DEFAULTS_INSTALL_DIR}/etc/pam.d" || exit 1
fi
# Prune Documentation
if [ -z "${SHED_PKG_LOCAL_OPTIONS[docs]}" ]; then
    rm -rf "${SHED_FAKE_ROOT}${SHED_PKG_DOCS_INSTALL_DIR}"
fi
