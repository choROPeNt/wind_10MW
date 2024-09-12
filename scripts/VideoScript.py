import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import cv2
import os

# Load the CSV file
input_file = r'C:\Abaqus_temp\wind_10MW\scripts\CSV Files\Displacements\Flapwise_Time_Disp.CSV'
df = pd.read_csv(input_file, header=None)

input_z = r'C:\Abaqus_temp\wind_10MW\scripts\coorZ_matrix.CSV'
loaded_matrix = np.loadtxt(input_z, delimiter=',')

# Reshape the data
rows_per_group = 167
num_rows = df.shape[0]
num_reps = num_rows // rows_per_group

reshaped_df = pd.DataFrame()
for i in range(num_reps):
    start_row = i * rows_per_group
    end_row = (i + 1) * rows_per_group
    
    if i == 0:
        slice_df = df.iloc[start_row:end_row].reset_index(drop=True)
    else:
        slice_df = df.iloc[start_row:end_row, 1].reset_index(drop=True)
    
    reshaped_df = pd.concat([reshaped_df, slice_df], axis=1)

reshaped_df.columns = [f'Col{i+1}' for i in range(reshaped_df.shape[1])]

# print(num_rows)
# print(num_reps)
# print(reshaped_df)
# print(reshaped_df.iloc[166,1:102])

# Create a colormap from light to dark
cmap = plt.get_cmap('viridis')  # 'viridis' is a good colormap from light to dark
colors = cmap(np.linspace(0, 1, rows_per_group))  # Generate 19 colors from the colormap

# Create a directory to store the frames
frames_dir = 'frames'
os.makedirs(frames_dir, exist_ok=True)

# Define fixed y-axis limits
y_min, y_max = reshaped_df.iloc[:, 1:102].min().min(), reshaped_df.iloc[:, 1:102].max().max()

# Manually setting y_max
y_max = 1

# Create and save each frame
for delta in range(rows_per_group-1):
    plt.figure(figsize=(12, 6))
    plt.plot(loaded_matrix, reshaped_df.iloc[delta, 1:102], marker='o', linestyle='-', color=colors[delta], label=f't = {reshaped_df.iloc[delta, 0]}')
    plt.xlabel('Z Coordinate (m)')
    plt.ylabel('Displacement (m)')
    plt.title(f'Displacement vs Z Coordinate at Time t = {round(reshaped_df.iloc[delta, 0],2)}')
    #plt.legend()
    
    # Set fixed y-axis limits and add grid
    plt.ylim(y_min, y_max)
    plt.grid(True)  # Add grid

    # Save the plot as an image
    filename = os.path.join(frames_dir, f'frame_{delta:03d}.png')
    plt.savefig(filename)
    plt.close()

# Create a video file from the frames
video_filename = r'C:\Abaqus_temp\scripts\animation.mp4'
frame_files = [os.path.join(frames_dir, f'frame_{delta:03d}.png') for delta in range(rows_per_group-1)]

# Read the first frame to get size
frame = cv2.imread(frame_files[0])
height, width, layers = frame.shape

# Create a VideoWriter object
video = cv2.VideoWriter(video_filename, cv2.VideoWriter_fourcc(*'mp4v'), 30, (width, height))  # 2 FPS

for frame_file in frame_files:
    frame = cv2.imread(frame_file)
    video.write(frame)

video.release()

# Clean up frames directory
for frame_file in frame_files:
    os.remove(frame_file)
os.rmdir(frames_dir)

print(f"Video saved as {video_filename}")
