import tensorflow as tf
import os
import wget
import tarfile
from pathlib import Path

# Force CPU usage
os.environ["CUDA_VISIBLE_DEVICES"] = "-1"

def download_and_extract_model():
    """Download the SSD MobileNet v2 model from TensorFlow model zoo if not already present."""
    model_url = "http://download.tensorflow.org/models/object_detection/tf2/20200711/ssd_mobilenet_v2_320x320_coco17_tpu-8.tar.gz"
    model_file = "ssd_mobilenet_v2_320x320_coco17_tpu-8.tar.gz"
    saved_model_dir = "ssd_mobilenet_v2/saved_model"
    
    # Create directories if they don't exist
    Path("ssd_mobilenet_v2").mkdir(exist_ok=True)
    
    # Download model if not already downloaded
    if not os.path.exists(model_file):
        print(f"Downloading model from {model_url}...")
        wget.download(model_url)
        print("\nDownload complete!")
    
    # Extract if the saved_model directory doesn't exist
    if not os.path.exists(saved_model_dir):
        print(f"Extracting model from {model_file}...")
        with tarfile.open(model_file, 'r:gz') as tar:
            # Use filter to address deprecation warning
            tar.extractall(filter='data')
        # Move the saved_model directory to the correct location
        os.rename("ssd_mobilenet_v2_320x320_coco17_tpu-8/saved_model", saved_model_dir)
        print("Extraction complete!")
    
    return saved_model_dir

def convert_to_tflite(saved_model_dir, output_file="object_labeler.tflite"):
    """Convert the SavedModel to TFLite format."""
    print(f"Converting model to TFLite format...")
    
    # Load the saved model
    print(f"Loading model from {saved_model_dir}...")
    model = tf.saved_model.load(saved_model_dir)
    
    # Initialize the TFLite converter
    converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
    
    # Set optimization flags
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    # Allow TF ops for compatibility
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS, 
        tf.lite.OpsSet.SELECT_TF_OPS
    ]
    
    # Enable experimental converter options
    converter.experimental_new_converter = True
    
    print("Running conversion (this may take several minutes)...")
    try:
        tflite_model = converter.convert()
        
        # Save the converted model
        with open(output_file, 'wb') as f:
            f.write(tflite_model)
        
        print(f"Conversion complete! TFLite model saved to {output_file}")
        print(f"Model size: {os.path.getsize(output_file) / (1024 * 1024):.2f} MB")
    except Exception as e:
        print(f"Error during conversion: {e}")
        
        # Try a simplified conversion if the full one fails
        print("Attempting simplified conversion...")
        converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
        tflite_model = converter.convert()
        
        with open(output_file, 'wb') as f:
            f.write(tflite_model)
        
        print(f"Basic conversion complete! TFLite model saved to {output_file}")
        print(f"Model size: {os.path.getsize(output_file) / (1024 * 1024):.2f} MB")

if __name__ == "__main__":
    # Ensure TensorFlow is using the correct version and CPU
    print(f"TensorFlow version: {tf.__version__}")
    print("Running on CPU only")
    
    # Download and extract the model
    saved_model_dir = download_and_extract_model()
    
    # Convert the model to TFLite
    convert_to_tflite(saved_model_dir)
    
    print("\nModel preparation complete!")
    print("Copy the 'object_labeler.tflite' file to your Flutter app's 'assets/ml/' directory.")