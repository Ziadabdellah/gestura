import 'package:gestura/core/cloud/cloud_set.dart';
import 'package:gestura/core/cloud/user_documents.dart';
import 'package:gestura/features/learner/data/learner_codecs.dart';
import 'package:gestura/features/learner/learner_cloud.dart';
import 'package:injectable/injectable.dart';

LearnerCloud firestoreLearnerCloud(UserDocuments documents) => LearnerCloud(
  progress: FirestoreCloudSet(documents, 'progress', const ProgressCodec()),
  cards: FirestoreCloudSet(documents, 'cards', const ReviewCardCodec()),
  activity: FirestoreCloudSet(documents, 'activity', const ActivityCodec()),
);

@module
abstract class LearnerCloudModule {
  @lazySingleton
  LearnerCloud firestore(UserDocuments documents) =>
      firestoreLearnerCloud(documents);
}
