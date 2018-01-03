# Sabayon Image for Check Overlay Ebuilds

This image could be used for verify SRC_URI of all ebuild of a list of overlays.

Default overlays verified are:
 * sabayon
 * sabayon-distro

```bash
  $# docker run --name check -v "/tmp/overlay_checks/:/tmp/overlay_checks/:rw" -it --rm geaaru/sabayon-check-overlay-amd64:latest
```
At the end of processing Under directory /tmp/overlay/overlay_checks will be available a file $OVERLAY_NAME_report.log with result of the analyze.

If overlay is not already installed on container script automatically try to add it. If is not available on default Gentoo
layman list it is possible use volume for add custom overlays files.

```bash
  $# docker run --name check -v "/etc/layman/:/etc/layman:ro" -v "/tmp/overlay_checks/:/tmp/overlay_checks/:rw" -e "SABAYON_OVERLAYS2CHECK=geaaru" -it --rm geaaru/sabayon-check-overlay-amd64:latest
```

## Available variables

| Variable   |  Default | Description |
|------------|----------|-------------|
| SABAYON_CHECK_RESULTDIR  | /tmp/overlay_checks  | Path where are write result logs.  |
| SABAYON_OVERLAYDIR | /var/lib/layman | Directory where layman store overlays |
| SABAYON_OVERLAYS2CHECK | sabayon sabayon-distro | Array of overlays to analyze |
| SABAYON_SYNC_OVERLAY | 0 | Set to 1 for execute layman -S before execute analyze |
| SABAYON_TMP_DISTDIR | /tmp/distfiles | Override DISTDIR variable |
| SABAYON_DEBUG | 0 | Enable debug |


