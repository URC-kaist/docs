---
title: "Maps"
weight: 3
draft: false
bookCollapseSection: true
---

# Maps

*Prepared with Codex in November 2026. This page follows the regenerated pipeline,
including its newer coverage for 2027 preparation; it is separate from the
March 2026 explanatory chapters.*

Navigation and the operator dashboard use two different kinds of maps. The
navigation stack needs terrain costs to plan a path. The dashboard needs RGB
imagery so that an operator can recognize places. These maps can cover the same
ground without sharing the same pixels, projection, origin, or encoding.

The current generation procedure is maintained in
[URC-kaist/map-pipeline](https://github.com/URC-kaist/map-pipeline), which
supersedes the original `lidar` experiments. This page explains the coordinate
contracts that connect its products to navigation and visualization. The
pipeline documentation owns the detailed conversion commands and source manifests.

## A map image needs a coordinate contract

A PNG is an array of colors or costs. By itself, it does not tell us where those
pixels are on Earth. We need to know the coordinate reference system (CRS),
pixel spacing, extent, and how the raster relates to the robot's frames.

A **datum** defines the geographic reference behind coordinates. A **projection**
maps geographic positions onto a plane. A ROS **frame** defines the origin and
axes in which a pose is expressed. Giving two datasets the same frame name does
not transform one datum or projection into the other.

The prepared MDRS profiles use these distinct coordinate systems:

| Data or product | Coordinate reference | Purpose |
| --- | --- | --- |
| Bare-earth DEM and default terrain grid | NAD83(2011) / UTM zone 12N, EPSG:6341 | Metre-based elevation and slope processing |
| Terrain anchor coordinates | NAD83(2011) geographic, EPSG:6318 | Locate the chosen local origin in the terrain CRS |
| Source RGB imagery | NAD83 / UTM zone 12N, EPSG:26912 | Georeferenced aerial image |
| Dashboard tile grid | Web Mercator, EPSG:3857, north-origin XYZ | Standard web-map tile addressing |
| Runtime robot poses | ROS `map`, through the running localization transform | Navigation goals, paths and robot pose |

EPSG:6341 and EPSG:26912 both use UTM zone 12N, but their datum definitions
differ. The pipeline transforms the data using its actual CRS; it does not
simply assign a new CRS label to unchanged coordinates.

## Terrain grid and the local map origin

The default terrain profile keeps its projected coordinates in the GeoTIFFs.
Its current output grid covers easting 518000–522000 m and northing
4248000–4253500 m, at 0.5 m per cell: 8000 columns by 11000 rows, or 4 km by
5.5 km. This supersedes the original 4 km by 5 km profile. The
[expanded-coverage record](https://github.com/URC-kaist/map-pipeline/blob/becb193b8067719e2cfe73acfd0aa54e5ee8b028/docs/EXPANDED-COVERAGE.md)
distinguishes the approximate operating area from URC 2027 rules and the chosen
500 m northern extension. Neither is an additional URC 2026 requirement.

The mosaic combines 0.5 m and 1 m sources with deterministic priorities; a
0.5 m output grid does not turn the latter into finer source measurements.

To produce local coordinates for Nav2, the pipeline projects the configured
anchor into that same CRS and subtracts its projected position:

```text
local_x = projected_easting  - anchor_easting
local_y = projected_northing - anchor_northing
```

There is no rotation in this operation. The default anchor is approximately
E=518000 m, N=4250500 m, giving a lower-left local map origin near
`[0, -2500, 0]`. The anchor need not be at the center of the output rectangle.
Read the exact anchor, dimensions and origin from the generated metadata rather
than reconstructing them from the image filename.

Raster bounds describe the **outer edges** of the grid. Pixel centers lie half
a cell inside those edges. TIFF and PNG rows run from north to south; Nav2's
map loader reverses the row direction when constructing its occupancy grid.
The generated YAML origin is the lower-left outer corner, not the first image
pixel's center.

Cropping or resizing an image changes this relationship. Keep its matching
YAML and metadata, and update the origin and resolution whenever the grid changes.

## Projected local coordinates are not automatically ROS map coordinates

Subtracting a UTM anchor creates a convenient local grid, but it does not make
that grid a true east-north-up tangent plane. UTM grid north and geographic north
can differ through grid convergence. A geographic datum choice also matters.

The running localization setup establishes the robot's `map` frame through its
datum, heading conventions and transforms. Before loading a generated terrain
map, establish how its grid axes and origin correspond to that frame. A
translation alone is sufficient only if the other coordinate assumptions already
agree; identical latitude/longitude labels are not that proof.

For a deployment, check the following together:

1. The source and output horizontal CRS, including their datum definitions.
2. The configured terrain anchor and the running localization datum.
3. Grid convergence, heading offsets and any required rotation between axes.
4. Known control locations transformed into the runtime `map` frame and back to
   geographic coordinates, including the boundaries of the loaded map.

The pipeline also provides a WGS84-centered azimuthal equidistant (AEQD) example
for the historical 1 km workflow. AEQD is another projection choice; it should
not be called ENU or treated as an exact recreation of the original crop.

The expanded DEM combines source years whose vertical metadata differs. The
2022 sources identify NAVD88/Geoid18; the inspected 2018/2020 CRS metadata does
not establish their vertical datum. Provider elevations are retained without
vertical conversion. Small overlap differences do not prove datum equivalence
or a seam-free slope field. A horizontal reprojection does not, by itself,
reconcile ellipsoidal and other height references.

## Slope products and the Nav2 loading contract

The terrain pipeline derives slopes from the DEM using Horn derivatives. It
keeps missing coverage explicit: cells without a complete valid neighborhood,
including the outer border, remain unknown rather than becoming apparently flat.

Its navigation image uses **raw-mode** values: 0–100 for slope cost and 255 for
unknown. The configured full-cost angle is 45 degrees. This is a terrain cost
encoding, not a validated statement that the rover can safely traverse every
lower-cost cell. Diagnostic slope and height PNGs are different products.

Load `occupancy.png` with its generated `map.yaml`; do not substitute the old
scale-mode YAML. Also review the Nav2 static layer's `trinary_costmap` setting
when graded costs are intended.

**Runtime integration remains separate from generation.** The older MR2 cropper
uses scale-mode settings and an older metadata schema. The new raw-mode image
and metadata are not drop-in replacements. Its cropping, coordinate alignment
and map-loading behavior must be adapted and checked before the new products
are described as deployed navigation maps. The old off-map blank-map fallback
does not establish that alignment or provide a missing terrain prior.

## Dashboard RGB tiles and geographic overlays

The RGB pipeline transforms the imagery into Web Mercator and crops it to the
DEM's outer footprint. That footprint is a geographic coverage choice, not a
request to encode imagery in Nav2's local coordinates. Missing RGB coverage
remains transparent, even inside the crop rectangle.

```text
RGB TIFF in EPSG:26912 ──> EPSG:3857 ──> XYZ tiles ──> MapLibre
DEM footprint in EPSG:6341 ──> transformed crop boundary

ROS map-frame pose ──> live /toLL ──> longitude/latitude ──> dashboard overlay
```

In XYZ addressing, x increases eastward and y increases southward from the
northern edge of the web-map grid. This is not the south-origin TMS convention.
The prepared tiles use 256-pixel PNGs and physical zoom levels 14–18, served at
`/tiles/naip/{z}/{x}/{y}.png`.

The dashboard must convert robot `map` poses to geographic coordinates using
the running localization transform. Its existing map-preview code calls
`/toLL`; the separate path-to-GeoPath converter uses its configured UTM transform
to supply geographic paths. Do not substitute a hardcoded image-anchor
subtraction for the runtime geographic conversion.

For the new tile collection, configure the raster source with the generated
bounds, XYZ scheme, tile size 256 and `maxzoom: 18`. Display zoom may reach 22
by enlarging existing tiles; it must not request nonexistent z19–22 files.
The source imagery is 0.6 m resolution: overzooming adds magnification, not detail.
The prepared viewer uses nearest raster sampling to show those pixel boundaries.

Tile routing must reach the generated collection on the same origin as the
dashboard, through a development proxy or nginx deployment. A working standalone
viewer verifies the tile products; it does not mean the original dashboard has
already been configured or deployed with them.

## Reproduce the products and verify registration

Follow the repository's supported environment and source-download instructions.
From the map-pipeline root, the prepared sequence is:

```bash
/usr/bin/python3 download_sources.py
/usr/bin/python3 prepare_sources.py
/usr/bin/python3 mosaic_dem.py
/usr/bin/python3 Lidar-pipeline/pipeline.py --output Lidar-pipeline/output/mdrs-expanded
/usr/bin/python3 RGB-pipeline/generate.py
/usr/bin/python3 RGB-pipeline/serve.py
```

Choose fresh output directories when repeating generation. Source checksums,
executed configuration, projection metadata and output hashes are part of the
result. MapLibre assets are needed only for the optional graphical viewer, not
for generating or serving tiles.

The original release records verify fresh-checkout regeneration and terrain
decoding by the native Nav2 library. The later expanded-coverage record verifies
the new DEM, terrain and RGB products, full operating-area coverage, tile
placement and standalone viewer. These
checks establish reproducibility and coordinate consistency within the selected
operations; they do not establish field registration. The documented environment
uses approximate datum transformations without a verified precise grid/epoch
correction. A tiny numerical roundtrip error is not an estimate of rover-to-image
accuracy. Verify registration using surveyed controls or live runtime transforms
before relying on the alignment in the field.

This page follows map-pipeline revision `becb193`, verified against the remote
on 18 November 2026. Consult its
[terrain contract](https://github.com/URC-kaist/map-pipeline/blob/becb193b8067719e2cfe73acfd0aa54e5ee8b028/Lidar-pipeline/README.md),
[RGB contract](https://github.com/URC-kaist/map-pipeline/blob/becb193b8067719e2cfe73acfd0aa54e5ee8b028/RGB-pipeline/README.md),
[supported environment](https://github.com/URC-kaist/map-pipeline/blob/becb193b8067719e2cfe73acfd0aa54e5ee8b028/ENVIRONMENT.md)
and [release verification](https://github.com/URC-kaist/map-pipeline/blob/becb193b8067719e2cfe73acfd0aa54e5ee8b028/RELEASE-REVIEW.md)
for the authoritative commands, profiles and tested boundaries.
