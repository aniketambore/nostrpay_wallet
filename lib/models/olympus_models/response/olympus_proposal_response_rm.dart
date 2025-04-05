import 'package:json_annotation/json_annotation.dart';

part 'olympus_proposal_response_rm.g.dart';

@JsonSerializable(createToJson: false)
class OlympusProposalResponseRM {
  const OlympusProposalResponseRM({required this.jitBolt11});

  @JsonKey(name: 'jit_bolt11')
  final String jitBolt11;

  static const fromJson = _$OlympusProposalResponseRMFromJson;
}
