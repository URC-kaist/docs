---
title: "Traversability Pipeline"
weight: 2
draft: false
bookCollapseSection: true
---

# Traversability Pipeline

*Written by Jaeuk Kim in 2026. 03*

> **Revision context:** This is the March 2026 explanation, with targeted
> factual corrections added with Codex on 18 November 2026. The full narrative
> has not yet been jointly human-reviewed. See
> [Implementation Notes]({{< ref "docs/2026_mr2/navigation/implementation_notes.md" >}})
> for the gravity/TF dependency and later real-mode localization settings.

Traversability is a quantized measure to describe if the region is safe to traverse.
So it could be thought as a fancier way to describe "obstacle cost", but the definition is more subtle since "traversability" depends on platform type. For instance, our 4WS4WD platform can safely traverse a slope up to 0.5 radians, and rough obstacle up to 0.1 meters high, without supervision.

In that, the pipeline must:
1. Acquire local terrain information in the rover's `base_link` frame. (`pc2_to_heightmap_node`)
2. Filter the data into traversability, tailored to our platform. (`traversability_filter_node`)
3. Incorporate the result into Nav2 costmap. (`mr2_nav2_plugins::TraversabilityLayer`)

## `pc2_to_heightmap_node`

Our first job is to get 3D information of terrain in `base_link` frame, namely "heightmap".
We have D435i in our hands, so we can get pointcloud stream from ROS2 realsense wrapper.
A custom node `pc2_to_heightmap_node` is created to poll the height, dividing the ROI in 0.1 meter resolution.
The ROI is fixed around the reliable sensor region (0.3-3.0 meters), 3m x 4m in dimension. So that is a grid of 1200 cells.
In that, some cells on the left and right will not collect any points since the sensor region is cone-shaped.

An array of pointcloud is iterated through.
First, we bin them into the cells after transforming them into `base_link` frame.
Now, we want to get a representative height for each cell.
For robustness and clarity, I chose to use the fifth rank using `std:nth_element` with O(N) time.
Why fifth? because large numbers can be outliers and can overshoot.
However, this was not thoroughly tested, and maybe it was okay to use the maximum height.
So I was just extra conservative with the intent to filter potential noise.
But it is tested that you should not use median or mean value for the representative height,
since that will decimate the terrain information.

The result is published in GridMap format, in `base_link` frame.

## `traversability_filter_node`

This node allows us to pass the filtering equations as a configuration file, using `grid_map_filters`.
This is the sole purpose why we use `grid_map` package in the first place;
It allows easier debugging and quick design iterations for our traversability pipeline.

The full implementation can be seen in `trav_pipeline.yaml`.

To explain the gist, we compute the following:
1. Inpainting: This fills nan values (cells with no points) by referencing the neighbor cells (so it is quite risky).
2. Gravity-referenced Slope: On a slope, the rover and its depth camera tilt together; the camera alone does not tell us which direction is vertical. We therefore need the gravity-up direction in the same frame as the surface normals. With `gravity_source: tf`, the node transforms `map`'s up vector into `base_link` and supplies the `gravity_x/y/z` layers; the filter computes the angle from the normals' dot product with that vector. The heightmap stays in `base_link`. An IMU-topic source is also supported, but is not the configured source. This requires a tilt-aware reference transform; see the unresolved dependency in the Implementation Notes.
3. Roughness: It is a positive measure of deviation from average of local patch. If this value is high, it means the region is lumpy.

With slope and roughness, the traversability is finally computed as a smooth step function.
The logic is that we ignore steep slope from shallow lumps, but still sensitive to absolute slope and large obstacles.


Given sigmoid function:
{{< katex display=true >}}
    \sigma_k(x) = \frac{1}{1 + e^{-k x}}
{{< /katex >}}

The smooth gating:
{{< katex display=true >}}
    f(s,r) =
    \max\left(
    2\,\sigma_{50}(s-0.5)\,\sigma_{200}(r-0.1),
    \;
    2\,\sigma_{50}(r-0.1)
    \right)
{{< /katex >}}

And then, the result is capped between 0 and 1.
The numbers (0.5, 0.1) are chosen from our platform's capability.
The numbers 50 and 200 dictate how smooth the function is.

You will notice that this is not traversability, but rather *obstructiveness*;
The number increases when you cannot traverse.
Yes, I just flipped it so it is more intuitive for Nav2 costmap integration.


## `TraversabilityLayer`: Custom Nav2 Costmap2D Plugin for GridMap

I referred to [official tutorial](https://docs.nav2.org/plugin_tutorials/docs/writing_new_costmap2d_plugin.html) to integrate the GridMap data.

Nav2 provides ObstacleLayer which gives options to take in raw sensor reading, including `scan` and `pointcloud2`.
However, it does not directly allow computed data in GridMap format.
There were numerous attempts to incorporate traversability to ObstacleLayer,
such as turning the traversability back to pointcloud to 'hack' the system.
But creating custom layer was much easier to customize it at the end.

TraversabilityLayer inherits `nav2_costmap_2d::CostmapLayer`. CostmapLayer holds public "master" costmap, and its own private costmap.
Master costmap is the one that is transferred between layers of each Nav2 costmap server. (I know the naming is confusing.)
The traversability is first drawn on the private costmap, and then it is combined to the master costmap.
This allows local cartography with persistance, since private costmap is not redrawn from scratch.

The combination method between GridMap to private costmap, and private to public costmap, can be customized by tweaking parameters.
Currently, we are using "maximum" for persistance, so the TraversabilityLayer maps anything and will never forget, until it is shifted out. Here, "never forget" contrasts with EMA decay: a lower later measurement does not gradually erase the retained maximum. Explicit clearing, resets and footprint clearing can still remove data.

For full detail, please refer to the source implementation.

## Room for improvement

- Traversability pipeline is one of the most taxing pipeline for its high computation requiremet, right next to the entire Nav2 pipeline.
We tried to decimate this by limiting the pointcloud stream rate, which made the entire system at least operable.
I think the pipeline can be further optimized without the help of beefy computer.

- In that, improve binning method in `pc2_to_heightmap_node`.

The launched configuration already sets `voxel_size_m: 0.01` m; the node's fallback default is 0.05 m. The old TODO to move to 0.01 m is therefore resolved, rather than a remaining optimization task.
