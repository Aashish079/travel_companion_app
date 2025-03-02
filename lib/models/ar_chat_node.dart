import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart';

class ARChatNode {
  final String id;
  final String message;
  final bool isUser;
  final Vector3 position;
  final Vector3 scale;
  final DateTime timestamp;
  
  ARChatNode({
  required this.id,
  required this.message,
  required this.isUser,
  required this.position,
  Vector3? scale,  // Make it nullable
  DateTime? timestamp,
}) : 
  scale = scale ?? Vector3(0.5, 0.5, 0.5),  // Assign default in initializer list
  timestamp = timestamp ?? DateTime.now();
  
  // Convert to ARNode for rendering
  ARNode toARNode() {
    return ARNode(
      type: NodeType.localGLTF2,
      uri: isUser 
          ? "assets/models/user_message_bubble.gltf"
          : "assets/models/system_message_bubble.gltf",
      scale: scale,
      position: position,
      rotation: Vector4(1, 0, 0, 0),
    );
  }
}