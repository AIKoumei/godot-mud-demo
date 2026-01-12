# Icon Set Explanation

## Overview
The `icon_set.png` file contains a collection of 8-bit pixel art icons designed for the 8-bit OS project. These icons are used throughout the operating system for desktop shortcuts, file types, and system functions.

## Icon Set Details

### Purpose
- Provide visual representation for system functions and file types
- Enhance the retro 8-bit aesthetic of the operating system
- Improve user experience through recognizable visual cues
- Maintain consistency in the visual design language

### Technical Specifications
- File format: PNG
- Dimensions: 512x512 pixels (grid of 16x16 icons, each 32x32 pixels)
- Color mode: RGB with transparency
- Color depth: 8-bit (256 colors)

### Icon List and Meanings

| Icon | Description | Usage |
|------|-------------|-------|
| 1. Gray folder with document | File Explorer | Desktop shortcut for file browser |
| 2. Blue folder | Generic Folder | Represents directories in file system |
| 3. Blue folder with gear | System Folder | Represents system directories |
| 4. White document with lines and "TXT" | Text File | Represents text documents |
| 5. Gray gear | Settings | System settings or configuration |
| 6. White document with "HELP" | Help Document | Help files or documentation |
| 7. Blue question mark | Help | Help or information function |
| 8. Gray trash bin | Trash/Recycle Bin | Deleted files storage |
| 9. Blue musical note | Music File | Audio or music files |

### Design Philosophy

#### Color Palette
- **Deep blue (#0F172A)**: Used for borders and accents, provides contrast
- **Medium blue (#3B82F6)**: Primary color for folder backgrounds and highlights
- **Light gray (#94A3B8)**: Secondary color for folder backgrounds and icons
- **White (#FFFFFF)**: Used for symbols, text labels, and highlights

#### Style Characteristics
- **8-bit pixel art**: Authentic retro computing aesthetic
- **Sharp edges**: No anti-aliasing for that classic pixel look
- **Simple shapes**: Easy to recognize at small sizes
- **Consistent proportions**: All icons follow the same visual language
- **High contrast**: Ensures good visibility against various backgrounds

### Usage Guidelines

#### Accessing Icons
To use an icon from the set, you need to specify the region of the texture to display:

```gdscript
# Example: Display the File Explorer icon
var texture_rect = TextureRect.new()
texture_rect.texture = load("res://assets/icons/icon_set.png")
texture_rect.region_enabled = true
texture_rect.region_rect = Rect2(0, 0, 32, 32)  # First icon (top-left corner)
```

#### Icon Coordinates
Each icon is located at specific coordinates in the 512x512 texture:

| Icon | Position (X, Y) |
|------|-----------------|
| 1. File Explorer | (0, 0) |
| 2. Blue Folder | (32, 0) |
| 3. System Folder | (64, 0) |
| 4. Text File | (0, 32) |
| 5. Settings | (32, 32) |
| 6. Help Document | (64, 32) |
| 7. Question Mark | (0, 64) |
| 8. Trash Bin | (32, 64) |
| 9. Music File | (64, 64) |

#### Implementation Examples

**Desktop Icon:**
```gdscript
func create_desktop_icon(name: String, icon_index: int, position: Vector2):
    var icon_node = Node2D.new()
    icon_node.position = position
    
    var texture_rect = TextureRect.new()
    texture_rect.texture = load("res://assets/icons/icon_set.png")
    texture_rect.region_enabled = true
    
    # Calculate icon position based on index
    var x = (icon_index % 3) * 32
    var y = (icon_index / 3) * 32
    texture_rect.region_rect = Rect2(x, y, 32, 32)
    
    texture_rect.size = Vector2(32, 32)
    texture_rect.position = Vector2(0, 0)
    icon_node.add_child(texture_rect)
    
    # Add label and other elements...
```

**File Type Icon:**
```gdscript
func get_file_icon(file_type: String) -> Rect2:
    match file_type:
        "folder":
            return Rect2(32, 0, 32, 32)  # Blue folder
        "system_folder":
            return Rect2(64, 0, 32, 32)  # System folder
        "txt":
            return Rect2(0, 32, 32, 32)  # Text file
        "music":
            return Rect2(64, 64, 32, 32)  # Music file
        _:
            return Rect2(0, 32, 32, 32)  # Default to text file
```

### Extending the Icon Set
To add new icons to the set:
1. Maintain the 32x32 pixel size per icon
2. Follow the established color palette
3. Add new icons in the next available position in the grid
4. Update this documentation with new icon details
5. Update the `icon_set_explanation.md` file

### Maintenance
- Keep a backup of the original PSD or source file for future edits
- Maintain consistency when adding new icons
- Document all changes in the project change log
- Test icons at various scales to ensure visibility and recognizability

## Conclusion
The icon set is an essential part of the 8-bit OS visual identity. By following these guidelines, you can ensure consistent and appropriate use of icons throughout the system, enhancing both the aesthetic appeal and user experience.
