import jinja2
import os
import sys

# Default to 2 if no argument provided
NUM_DRONES = 2
if len(sys.argv) > 1:
    NUM_DRONES = int(sys.argv[1])

# Load the template
template_filename = "swarm.sdf.jinja"
if not os.path.exists(template_filename):
    print(f"Error: {template_filename} not found!")
    exit(1)

with open(template_filename, "r") as f:
    template_content = f.read()

template = jinja2.Template(template_content)

# Render the SDF
rendered_sdf = template.render(num_drones=NUM_DRONES)

# Save to file
filename = "generated_swarm.sdf"
with open(filename, "w") as f:
    f.write(rendered_sdf)

print(f"Success: Generated {filename} with {NUM_DRONES} drones.")
