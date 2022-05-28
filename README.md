# [Shop Core](https://hlmod.ru/threads/shop-core-fork.38351/)


| Status | Build Status | Discord |
|:------:|:------------:|:-------:|
| Passive updates | [![Build](https://github.com/hlmod/Shop-Core/actions/workflows/build.yml/badge.svg)](https://github.com/hlmod/Shop-Core/actions/workflows/build.yml) | [![Discord](https://img.shields.io/discord/315148933792006144.svg)](https://discord.gg/NTrASWm)

## Requirements
- [SourceMod](https://www.sourcemod.net/downloads.php?branch=stable) 1.10+
- Database section in `addons/sourcemod/configs/databases.cfg`
For SQLite usage, **shop supports MySQL and recommended to use**
```
"shop"
{
        "driver"    "sqlite"
        "database"  "shop_core"
}
```
- (Optional) [Steamworks](https://forums.alliedmods.net/showthread.php?t=229556)

## Installation
- Extract archive from [Releases](../../releases) page to server directory
- (Optional) Setup sorting if you need (create a file `addons/sourcemod/configs/shop/shop_sort.txt` and add categories.
Example:
```
aura
ability
stuff
```
Category name can be found in code of modules. Example
```h
CategoryId:category_id = Shop_RegisterCategory("stuff", "Разное", ""); // Category unique name - stuff
```
or
```h
#define CATEGORY    "aura"// Category unique name - aura

// some lines below
new CategoryId:category_id = Shop_RegisterCategory(CATEGORY, sName, sDescription); // Category name in constant CATEGORY
```

## Useless links
- [HLMod Thread](https://hlmod.ru/threads/shop-core-fork.38351/)
- [License](https://github.com/hlmod/Shop-Core/blob/master/LICENSE.md)
- For translation make a [PR](https://github.com/hlmod/Shop-Core/pulls) on our master branch
- How many servers uses this plugin [Statistics](https://stats.tibari.dev/plugin/8)
