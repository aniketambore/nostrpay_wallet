import 'package:json_annotation/json_annotation.dart';

part 'olympus_proposal_request_rm.g.dart';

@JsonSerializable(createFactory: false)
class OlympusProposalRequestRM {
  const OlympusProposalRequestRM({
    required this.bolt11,
    required this.feeId,
  });

  final String bolt11;
  @JsonKey(name: 'fee_id')
  final String feeId;

  Map<String, dynamic> toJson() => _$OlympusProposalRequestRMToJson(this);
}
