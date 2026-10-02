/* libnetd_client.so (vendor) for mtk-ril.so.
 *
 * mtk-ril.so needs libnetd_client.so, which is system-only on Android 13,
 * so its dlopen would fail before any symbol lookup; TARGET_LD_SHIM_LIBS
 * cannot satisfy a missing DT_NEEDED, a vendor library of that name can.
 *
 * The only import is protectFromVpn, called by createRawSocket for the IPv6
 * router-advertisement socket of a data call; a negative return aborts the
 * RA socket.  Returning 0 is fine: the socket is already bound to the ccmni
 * interface, and a vendor process cannot reach netd's fwmarkd anyway.
 */
int protectFromVpn(int socketFd) {
    (void)socketFd;
    return 0;
}
