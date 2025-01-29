# CF IOReport Demo

## What is this?

This is a demo of calling some of CF IOReport functionalities (undocumented API)
from Zig inspired by Macmon (Sudoless performance monitoring CLI tool for Apple
Silicon processors) and
[the article by the auther of Macmon](https://medium.com/@vladkens/how-to-get-macos-power-metrics-with-rust-d42b0ad53967).

The original ambition was simply to create a zig version of
[Macmon](https://github.com/vladkens/macmon) but I've decided to abandon it for
now as I just don't feel like working on it anymore (especially after I noticed
very arbitary nature of how temp reading works between different versions of
Apple silicons...).

So least I can do is to share the code as there are not many examples of calling
CF APIs from Zig and hope it would server as a good starting point for anyone
who wants to write a CF binding in Zig (obj-c is hard) or, even better, inspire
someone to continue the work...

## How to run

In Apple Silicon Mac, you should just be able to run.

```bash
zig build run
```
