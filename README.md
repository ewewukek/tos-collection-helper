### Collection Helper

Simple addon that tracks any items that are somehow related to collections (including crafted ones). It builds dependency lists at startup and uses them to calculate required amounts for each item and adds labels to their displayed names (works for tooltips, item pickup pop-ups and for market lists). Also it looks for crafted items in inventory and counts their requirements as no longer needed (they may be required for other collections/crafts nonetheless)

Examples:

![](doc/item_have_lt_required.png?raw=true)

42 is the total amount of `Hook`s needed, 36 is the current amount of it in inventory

![](doc/item_have_ge_required.png?raw=true)

1 `Arch Rod` is needed for some collection or craft. Don't have it in inventory yet, but have necessary amount of recipes

![](doc/item_no_longer_required.png?raw=true)

Have enough `Alter Rod`s in inventory, so recipe items are not needed anymore. Any items that are not related to collections don't have any labels either. (actually addon adds a dark green `(0)` label to such items by default, but I've disabled it in my configuration file, which is described below)

#### Installation

(will be added later) for now, simply copy `🐱collectionhelper.ipf` to your `data` folder

#### Configuration

You may need to create `…/TreeOfSavior/addons/collectionhelper` directory if installing the addon manually. It will be populated with default configuration at first start with following content:

```
{
    "have_ge_required_tpl": "{@st66b}{s20}({#00FF00}%s{/}){/}{/}{/} %s",
    "have_lt_required_tpl": "{@st66b}{s20}({#FFFF00}%s{/}/{#FFFF00}%s{/}){/}{/} %s",
    "no_longer_required_tpl": "{@st66b}{s20}({#00A000}0{/}){/}{/} %s",
    "show_no_longer_required_items": true,
    "version": "1.0.0"
}
```

- `have_ge_required_tpl` - template used when player has enough of required items in their inventory
- `have_lt_required_tpl` - used when player have less than required
- `no_longer_required_tpl` - template used to denote items that no longer required, but are related to collections
- `show_no_longer_required_items` - self explanatory
- `version` - (internal, modifying it will result in overwriting configuration with default one)

Template syntax is quite simple. `{…}` denotes an opening tag and `{/}` is for closing. `@st66b` is the style used for market lists, but there are others (eg. `@st45` or `@st60`). `s20` is the font size and `#FFFFFF` is the color. Feel free adjust templates to your liking. Just do not add or remove `%s` - they are replaced with actual numbers and the item name. Execute `COLLECTIONHELPER_ON_INIT()` in dev console to reload configuration on the fly

#### Credits

- TOS Addon Comunity for their great job (Addon Manager, AC-Util and much more)
- Xanaxiel for Tooltip Helper (awesome addon)
- TwoLaid, TOSHACK and others for ipf-tools (nice tar-like tool for .ipf files)
