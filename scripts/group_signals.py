#!/usr/bin/env python3
import sys
import re
import os

def parse_variables(content):
    variables = {}
    pattern = re.compile(r'\((\d+)\):\s*Variable\(\(')
    for match in pattern.finditer(content):
        var_id = int(match.group(1))
        start_idx = match.start()
        scan_idx = match.end()
        paren_count = 2
        while paren_count > 0 and scan_idx < len(content):
            char = content[scan_idx]
            if char == '(':
                paren_count += 1
            elif char == ')':
                paren_count -= 1
            scan_idx += 1
        
        block = content[start_idx:scan_idx]
        
        name_match = re.search(r'\bname:\s*"([^"]+)"', block)
        if name_match:
            name = name_match.group(1)
            variables[var_id] = {
                'name': name,
                'block': block
            }
    return variables

def get_block_range(content, start_pattern, open_char, close_char):
    match = re.search(start_pattern, content)
    if not match:
        return None
    start_idx = match.start()
    scan_idx = match.end()
    count = 1
    while count > 0 and scan_idx < len(content):
        char = content[scan_idx]
        if char == open_char:
            count += 1
        elif char == close_char:
            count -= 1
        scan_idx += 1
    return start_idx, scan_idx

def map_to_group(name):
    match = re.match(r'^([ms]\d+)_(aw|w|b|ar|r)(.*)$', name, re.IGNORECASE)
    if match:
        prefix = match.group(1).upper()
        channel = match.group(2).upper()
        return (prefix, channel)
    
    match_prefix = re.match(r'^([ms]\d+)_(.*)$', name, re.IGNORECASE)
    if match_prefix:
        prefix = match_prefix.group(1).upper()
        return (prefix, "OTHER")
        
    return None

def set_variable_color(block, color_name):
    color_val = f'Some("{color_name}")' if color_name else 'None'
    new_block, _ = re.subn(r'\bcolor:\s*(None|Some\([^)]+\)),', f'color: {color_val},', block)
    return new_block

def main():
    if len(sys.argv) < 2:
        print("Usage: group_signals.py <path_to_surf_ron>")
        sys.exit(1)
        
    filepath = sys.argv[1]
    if not os.path.exists(filepath):
        print(f"Error: File '{filepath}' does not exist.")
        sys.exit(1)
        
    with open(filepath, 'r') as f:
        content = f.read()
        
    variables = parse_variables(content)
    if not variables:
        print("No variables found in the state file.")
        sys.exit(0)
        
    max_var_id = max(variables.keys())
    next_id = max_var_id + 1
    
    grouped_vars = {}
    ungrouped_vars = []
    
    for var_id, var_info in variables.items():
        name = var_info['name']
        path = map_to_group(name)
        
        color = None
        if 'clk' in name.lower():
            color = "Yellow"
        elif 'rst' in name.lower() or 'reset' in name.lower():
            color = "Gray"
        elif path:
            chan = path[1]
            if chan == "AW":
                color = "Orange"
            elif chan == "W":
                color = "Yellow"
            elif chan == "B":
                color = "Green"
            elif chan == "AR":
                color = "Cyan"
            elif chan == "R":
                color = "Blue"
                
        variables[var_id]['block'] = set_variable_color(var_info['block'], color)
        
        if path:
            if path not in grouped_vars:
                grouped_vars[path] = []
            grouped_vars[path].append(var_id)
        else:
            ungrouped_vars.append(var_id)
            
    def ungrouped_sort_key(var_id):
        name = variables[var_id]['name'].lower()
        if 'clk' in name:
            return (0, name)
        if 'rst' in name or 'reset' in name:
            return (1, name)
        return (2, name)
        
    ungrouped_vars.sort(key=ungrouped_sort_key)
    
    tree_items = []
    new_displayed_items = {}
    
    for var_id in ungrouped_vars:
        tree_items.append({
            'item_ref': var_id,
            'level': 0,
            'unfolded': 'true',
            'selected': 'false'
        })
        new_displayed_items[var_id] = variables[var_id]['block']
        
    prefixes = sorted(list(set(path[0] for path in grouped_vars.keys())))
    def prefix_sort_key(pref):
        m = re.match(r'^([MS])(\d+)$', pref)
        if m:
            t = 0 if m.group(1) == 'M' else 1
            return (t, int(m.group(2)))
        return (2, pref)
    prefixes.sort(key=prefix_sort_key)
    
    channel_order = ["AW", "W", "B", "AR", "R", "OTHER"]
    
    for pref in prefixes:
        pref_id = next_id
        next_id += 1
        
        tree_items.append({
            'item_ref': pref_id,
            'level': 0,
            'unfolded': 'true',
            'selected': 'false'
        })
        
        new_displayed_items[pref_id] = f"""({pref_id}): Group((
                name: "{pref}",
                color: None,
                background_color: None,
                content: [],
                is_open: false,
            ))"""
            
        for chan in channel_order:
            path = (pref, chan)
            if path in grouped_vars:
                chan_id = next_id
                next_id += 1
                
                tree_items.append({
                    'item_ref': chan_id,
                    'level': 1,
                    'unfolded': 'true',
                    'selected': 'false'
                })
                
                new_displayed_items[chan_id] = f"""({chan_id}): Group((
                name: "{chan}",
                color: None,
                background_color: None,
                content: [],
                is_open: false,
            ))"""
                
                chan_vars = sorted(grouped_vars[path], key=lambda vid: variables[vid]['name'].lower())
                for var_id in chan_vars:
                    tree_items.append({
                        'item_ref': var_id,
                        'level': 2,
                        'unfolded': 'true',
                        'selected': 'false'
                    })
                    new_displayed_items[var_id] = variables[var_id]['block']
                    
    tree_lines = []
    for item in tree_items:
        tree_lines.append(f"""                (
                    item_ref: ({item['item_ref']}),
                    level: {item['level']},
                    unfolded: {item['unfolded']},
                    selected: {item['selected']},
                ),""")
    new_items_tree_str = "items_tree: (\n            items: [\n" + "\n".join(tree_lines) + "\n            ],\n        )"
    
    disp_lines = []
    for key in sorted(new_displayed_items.keys()):
        block = new_displayed_items[key].strip()
        if not block.endswith(','):
            block += ','
        indented_block = ""
        for line in block.split('\n'):
            indented_block += "            " + line.strip() + "\n"
        disp_lines.append(indented_block.rstrip())
        
    new_displayed_items_str = "displayed_items: {\n" + "\n".join(disp_lines) + "\n        }"
    
    tree_range = get_block_range(content, r'items_tree:\s*\(', '(', ')')
    disp_range = get_block_range(content, r'displayed_items:\s*\{', '{', '}')
    
    if not tree_range or not disp_range:
        print("Error: Could not locate items_tree or displayed_items blocks in state file.")
        sys.exit(1)
        
    tree_start, tree_end = tree_range
    disp_start, disp_end = disp_range
    
    if tree_start > disp_start:
        print("Error: unexpected structure (displayed_items before items_tree).")
        sys.exit(1)
        
    new_content = (
        content[:tree_start] +
        new_items_tree_str +
        content[tree_end:disp_start] +
        new_displayed_items_str +
        content[disp_end:]
    )
    
    new_ref_counter = next_id - 1
    new_content = re.sub(
        r'display_item_ref_counter:\s*\d+',
        f'display_item_ref_counter: {new_ref_counter}',
        new_content
    )
    
    with open(filepath, 'w') as f:
        f.write(new_content)
        
    print(f"Successfully grouped signals in '{filepath}' into masters/slaves and channel subgroups!")

if __name__ == "__main__":
    main()
