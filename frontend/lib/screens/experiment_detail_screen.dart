// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';
// import '../components/ai_assistant/ai_assistant_button.dart';
// import '../models/experiment.dart';
// import '../providers/progress_provider.dart';

// class ExperimentDetailScreen extends StatefulWidget {
//   final Experiment experiment;

//   const ExperimentDetailScreen({Key? key, required this.experiment}) : super(key: key);

//   @override
//   _ExperimentDetailScreenState createState() => _ExperimentDetailScreenState();
// }

// class _ExperimentDetailScreenState extends State<ExperimentDetailScreen> with TickerProviderStateMixin {
//   int currentStepIndex = 0;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   VideoPlayerController? _videoController;
//   ChewieController? _chewieController;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//     _animationController.forward();
//     _initializeVideo(currentStepIndex);
//   }

//   void _initializeVideo(int stepIndex) {
//     final step = widget.experiment.steps[stepIndex];
//     if (step.mediaUrl != null && step.mediaUrl!.endsWith('.mp4')) {
//       _videoController = VideoPlayerController.networkUrl(Uri.parse(step.mediaUrl!));
//       _chewieController = ChewieController(
//         videoPlayerController: _videoController!,
//         autoPlay: false,
//         looping: false,
//         aspectRatio: 16 / 9,
//         errorBuilder: (context, errorMessage) => Container(
//           height: 200,
//           decoration: BoxDecoration(
//             color: Colors.grey[200],
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.videocam_off_outlined, size: 40, color: Colors.grey[500]),
//                 SizedBox(height: 8),
//                 Text('Video not available', style: TextStyle(color: Colors.grey[600])),
//               ],
//             ),
//           ),
//         ),
//       );
//       _videoController!.initialize().then((_) => setState(() {}));
//     } else {
//       _videoController?.dispose();
//       _chewieController?.dispose();
//       _videoController = null;
//       _chewieController = null;
//     }
//   }

//   void _nextStep() {
//     if (currentStepIndex < widget.experiment.steps.length - 1) {
//       _animationController.reset();
//       setState(() {
//         currentStepIndex++;
//         _initializeVideo(currentStepIndex);
//       });
//       _animationController.forward();
//     }
//   }

//   void _toggleStepCompletion(int stepIndex) {
//     Provider.of<ProgressProvider>(context, listen: false)
//         .toggleStepCompletion(widget.experiment.id, stepIndex);
//     if (Provider.of<ProgressProvider>(context, listen: false)
//         .isExperimentCompleted(widget.experiment.id, widget.experiment.steps.length)) {
//       _showCompletionDialog();
//     }
//   }

//   void _showCompletionDialog() {
//     showDialog(
//       context: context,
//       builder: (ctx) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   color: Colors.yellow[100],
//                   borderRadius: BorderRadius.circular(40),
//                 ),
//                 child: Icon(
//                   Icons.star,
//                   size: 40,
//                   color: Colors.yellow[700],
//                 ),
//               ),
//               SizedBox(height: 16),
//               Text(
//                 'Congratulations!',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.black,
//                   fontFamily: 'ComicSans',
//                 ),
//               ),
//               SizedBox(height: 8),
//               Text(
//                 'You earned the Science Star badge! ⭐',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[700],
//                   fontFamily: 'ComicSans',
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(ctx),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.black,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 child: Text(
//                   'Awesome!',
//                   style: TextStyle(fontFamily: 'ComicSans', fontSize: 16),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _videoController?.dispose();
//     _chewieController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentStep = widget.experiment.steps[currentStepIndex];
//     final progress = (currentStepIndex + 1) / widget.experiment.steps.length;
//     final progressProvider = Provider.of<ProgressProvider>(context);

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         leading: IconButton(
//           icon: Container(
//             padding: EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(Icons.arrow_back, size: 20),
//           ),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               widget.experiment.title,
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black,
//                 fontFamily: 'ComicSans',
//               ),
//             ),
//             SizedBox(height: 2),
//             Text(
//               'Step ${currentStepIndex + 1} of ${widget.experiment.steps.length}',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//                 fontWeight: FontWeight.w500,
//                 fontFamily: 'ComicSans',
//               ),
//             ),
//           ],
//         ),
//         bottom: PreferredSize(
//           preferredSize: Size.fromHeight(8),
//           child: Container(
//             margin: EdgeInsets.symmetric(horizontal: 16),
//             height: 4,
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(2),
//             ),
//             child: FractionallySizedBox(
//               alignment: Alignment.centerLeft,
//               widthFactor: progress,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             SizedBox(height: 24),
//             // Materials Section
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: 16),
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: Colors.black,
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Icon(
//                           Icons.inventory_2_outlined,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       Text(
//                         'Materials Needed',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.black,
//                           fontFamily: 'ComicSans',
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 16),
//                   ...widget.experiment.materials.map(
//                     (material) => Container(
//                       margin: EdgeInsets.only(bottom: 8),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Container(
//                             width: 6,
//                             height: 6,
//                             margin: EdgeInsets.only(top: 8, right: 12),
//                             decoration: BoxDecoration(
//                               color: Colors.black,
//                               borderRadius: BorderRadius.circular(3),
//                             ),
//                           ),
//                           Expanded(
//                             child: Text(
//                               material,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.grey[700],
//                                 height: 1.5,
//                                 fontFamily: 'ComicSans',
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),
//             // Progress Section
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: 16),
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.check_circle_outline,
//                     color: Colors.green[700],
//                     size: 24,
//                   ),
//                   SizedBox(width: 12),
//                   Text(
//                     'Progress: ${progressProvider.completedSteps[widget.experiment.id]?.length ?? 0}/${widget.experiment.steps.length} steps completed',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                       fontFamily: 'ComicSans',
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),
//             // Current Step Section
//             FadeTransition(
//               opacity: _fadeAnimation,
//               child: Container(
//                 margin: EdgeInsets.symmetric(horizontal: 16),
//                 padding: EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 10,
//                       offset: Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: Colors.black,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Center(
//                             child: Text(
//                               '${currentStep.stepNumber}',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w700,
//                                 fontFamily: 'ComicSans',
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             'Step ${currentStep.stepNumber}',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.black,
//                               fontFamily: 'ComicSans',
//                             ),
//                           ),
//                         ),
//                         Checkbox(
//                           value: progressProvider.isStepCompleted(widget.experiment.id, currentStepIndex),
//                           onChanged: (_) => _toggleStepCompletion(currentStepIndex),
//                           activeColor: Colors.green[700],
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 20),
//                     Text(
//                       currentStep.instruction,
//                       style: TextStyle(
//                         fontSize: 18,
//                         color: Colors.grey[800],
//                         height: 1.6,
//                         fontWeight: FontWeight.w400,
//                         fontFamily: 'ComicSans',
//                       ),
//                     ),
//                     if (currentStep.mediaUrl != null) ...[
//                       SizedBox(height: 20),
//                       Container(
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 8,
//                               offset: Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(12),
//                           child: currentStep.mediaUrl!.endsWith('.mp4') && _chewieController != null
//                               ? SizedBox(
//                                   height: 200,
//                                   child: Chewie(controller: _chewieController!),
//                                 )
//                               : Image.network(
//                                   currentStep.mediaUrl!,
//                                   height: 200,
//                                   fit: BoxFit.cover,
//                                   errorBuilder: (context, error, stackTrace) => Container(
//                                     height: 200,
//                                     decoration: BoxDecoration(
//                                       color: Colors.grey[200],
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: Center(
//                                       child: Column(
//                                         mainAxisAlignment: MainAxisAlignment.center,
//                                         children: [
//                                           Icon(Icons.image_not_supported_outlined,
//                                               size: 40, color: Colors.grey[500]),
//                                           SizedBox(height: 8),
//                                           Text('Image not available',
//                                               style: TextStyle(
//                                                 color: Colors.grey[600],
//                                                 fontFamily: 'ComicSans',
//                                               )),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 24),
//             // Navigation Button or Completion Message
//             if (currentStepIndex < widget.experiment.steps.length - 1)
//               Container(
//                 width: double.infinity,
//                 margin: EdgeInsets.symmetric(horizontal: 16),
//                 child: ElevatedButton(
//                   onPressed: _nextStep,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.black,
//                     foregroundColor: Colors.white,
//                     padding: EdgeInsets.symmetric(vertical: 18),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Next Step',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           fontFamily: 'ComicSans',
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                       Icon(Icons.arrow_forward, size: 20),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               Container(
//                 width: double.infinity,
//                 margin: EdgeInsets.symmetric(horizontal: 16),
//                 child: Container(
//                   padding: EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.green[50],
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: Colors.green[200]!),
//                   ),
//                   child: Column(
//                     children: [
//                       Container(
//                         width: 60,
//                         height: 60,
//                         decoration: BoxDecoration(
//                           color: Colors.green[100],
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         child: Icon(
//                           Icons.check_circle_outline,
//                           size: 30,
//                           color: Colors.green[700],
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       Text(
//                         'Experiment Complete!',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.green[800],
//                           fontFamily: 'ComicSans',
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       Text(
//                         'Great job completing all the steps!',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.green[700],
//                           fontFamily: 'ComicSans',
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             SizedBox(height: 100), // Space for floating action button
//           ],
//         ),
//       ),
//       floatingActionButton: AIAssistantButton(
//         experimentId: widget.experiment.id,
//         currentStepContext: 'Step ${currentStep.stepNumber}: ${currentStep.instruction}',
//       ),
//     );
//   }
// }