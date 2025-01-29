# CF IOReport Demo

## What is this?
This is a demo of how to use CF IOReport from Zig inspired by [Macmon (Sudoless performance monitoring 
CLI tool for Apple Silicon processors) and the article](https://github.com/vladkens/macmon).

The original ambition was simply to create a zig version of [Macmon](https://github.com/vladkens/macmon) 
but I've decided to abandon it for now as I just don't feel like working on it anymore (especially after 
I noticed very arbitary nature of how temp reading works between different versions of Apple silicons...). 

So, at least, I thoguth what I could do is to share the code as there are not many examples of calling CF
functionalities from Zig and hope it would inspire someone to continue the work...

## How to run
In Apple Silicon Mac, you should just be able to run.
```bash
 zig build run
```

