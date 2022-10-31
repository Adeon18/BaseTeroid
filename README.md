# BaseTeroid
**Baseteroid** is a game in a **_non-Euclidean space_** and written using **only a fragment
shader with a [ShaderToy](https://www.shadertoy.com/) service. The game is heavily inspired by a popular arcade game **"Asteroid"**,
released in _November 1979_.

**You can play out game _without downloading it_ it on the shadertoy service [here](https://www.shadertoy.com/view/csS3RR)**.

### Development stages
The development stages are the following:
- **Stage 1:** Create a base game with **raymarcher** as renderer `[current stage]`
- **Stage 2:** Add a black hole visualization which will warp the space around it.
- **Stage 3:** Add black hole affected physics, which will change the gameplay

## Stage 1
- [x] Create a **raymarcher**
- [x] Handle player input
- [x] Give player inertia and movement
- [x] Make asteroids randomly spawn

#### Raymarching

_See [render.glsl](./utility/render.glsl) and [main.glsl](./main.glsl)._

**Ray marching** -  is a class of rendering methods for 3D computer graphics where rays are traversed iteratively, effectively dividing each ray into smaller ray segments, sampling some function at each step.

In a shader, it is basically launching a ray for each _texel_, and calculating the distance to hit object for each of those rays.

Raymarching "marches" using **circles**, at each iteration taking the _smallest_ distance to any object.

![img](./img/ray_march_example.png)

Whether a circle collides with some object is determined by the **signed distance functions** for those respective objects.

Lighting is also made with raymarching from object to light source and looking whether we have hit the light source or if there is something in the way.

Here is an example of a simple Raymarcher we wrote for this project:

![img](./img/raymarching.gif)

#### The Base Game
The game is written _obviously_ in 3D, but it is entirely **top-down**, as in Asteroid but all the render is in 3D. So far it has a ship with inertia and asteroid spawning.

Here is how the game looks after the first development stage:

![img](./img/part1_progress.gif)

---

## Stage 2
_To be continued..._

---

## Stage 3
_To be continued..._

---

## Collaborators

- [Olexiy Hoev](https://github.com/alexg-lviv)
- [Ostap Trush](https://github.com/Adeon18)
- [Bohdan Ruban](https://github.com/iamthewalrus67)
- [Mykhailo Bondarenko](https://github.com/michael-2956)

### Lucky Cat :D

![cat](./img/cat.gif)