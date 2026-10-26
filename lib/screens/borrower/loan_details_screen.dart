import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LoanDetailsScreen extends StatefulWidget {
  const LoanDetailsScreen({super.key,required this.loan});
  final Map<String,dynamic> loan;
  @override State<LoanDetailsScreen> createState()=>_LoanDetailsScreenState();
}
class _LoanDetailsScreenState extends State<LoanDetailsScreen> with SingleTickerProviderStateMixin {
  static const green=Color(0xFF168B62);
  late final TabController tabs;
  final api=ApiService();
  bool loadingI=true,loadingP=true;
  String? errorI,errorP;
  List<Map<String,dynamic>> installments=[],payments=[];
  int? get loanId=>int.tryParse(widget.loan['loanId']?.toString()??'');
  @override void initState(){super.initState();tabs=TabController(length:2,vsync:this);loadI();loadP();}
  String money(dynamic v){final n=double.tryParse(v?.toString()??'');return n==null?'—':'LKR ${n.toStringAsFixed(2)}';}
  String date(dynamic v){final d=DateTime.tryParse(v?.toString()??'');return d==null?(v?.toString()??'—'):'${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';}
  Future<void> loadI() async {if(loanId==null){setState(()=>{loadingI=false,errorI='Loan ID is missing'});return;}try{final r=await api.getLoanInstallments(loanId!);if(mounted)setState(()=>{installments=r.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList(),loadingI=false});}on ApiException catch(e){if(mounted)setState(()=>{errorI=e.message,loadingI=false});}catch(_){if(mounted)setState(()=>{errorI='Could not load repayment schedule',loadingI=false});}}
  Future<void> loadP() async {if(loanId==null){setState(()=>{loadingP=false,errorP='Loan ID is missing'});return;}try{final r=await api.getLoanPayments(loanId!);if(mounted)setState(()=>{payments=r.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList(),loadingP=false});}on ApiException catch(e){if(mounted)setState(()=>{errorP=e.message,loadingP=false});}catch(_){if(mounted)setState(()=>{errorP='Could not load payment history',loadingP=false});}}
  @override void dispose(){tabs.dispose();api.dispose();super.dispose();}
  @override Widget build(BuildContext context){final l=widget.loan;return Scaffold(backgroundColor:const Color(0xFFF5FAF7),appBar:AppBar(title:Text(l['loanCode']?.toString()??'Loan Details'),backgroundColor:green,foregroundColor:Colors.white,bottom:TabBar(controller:tabs,tabs:const[Tab(text:'Repayment Schedule'),Tab(text:'Payment History')])),body:Column(children:[
    Container(width:double.infinity,color:Colors.white,padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Loan status: ${l['status']??'UNKNOWN'}',style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
      const SizedBox(height:12),_row('Requested amount',money(l['requestedAmount'])),_row('Approved amount',money(l['approvedAmount'])),_row('Outstanding balance',money(l['outstandingBalance'])),_row('Repayment period',l['repaymentMonths']==null?'—':'${l['repaymentMonths']} months'),_row('Purpose',l['purpose']?.toString()??'Not specified'),
      if((l['rejectionReason']?.toString()??'').isNotEmpty)Text('Reason: ${l['rejectionReason']}',style:const TextStyle(color:Colors.red))
    ])),
    Expanded(child:TabBarView(controller:tabs,children:[_list(loadingI,errorI,installments,true,loadI),_list(loadingP,errorP,payments,false,loadP)]))
  ]));}
  Widget _row(String label,String value)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Row(children:[Expanded(child:Text(label,style:const TextStyle(color:Colors.black54))),Flexible(child:Text(value,textAlign:TextAlign.end,style:const TextStyle(fontWeight:FontWeight.bold)))]));
  Widget _list(bool loading,String? error,List<Map<String,dynamic>> data,bool isI,Future<void> Function() retry){
    if(loading)return const Center(child:CircularProgressIndicator());
    if(error!=null)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error),TextButton(onPressed:retry,child:const Text('Try again'))]));
    if(data.isEmpty)return Center(child:Text(isI?'No repayment installments available yet.':'No payments recorded for this loan yet.'));
    return RefreshIndicator(onRefresh:retry,child:ListView.separated(padding:const EdgeInsets.all(12),itemCount:data.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){
      final d=data[i];final title=isI?'Installment ${d['installmentNumber']??i+1}':(d['paymentCode']?.toString()??'Payment');
      final amount=isI?d['principalDue']:d['amount'];final state=d['status']?.toString()??'UNKNOWN';
      final subtitle=isI?'Due: ${date(d['dueDate'])}\nPaid: ${money(d['paidAmount'])} • Remaining: ${money(d['remainingAmount'])}':'Date: ${date(d['paymentDate'])}\nSource: ${d['source']??'—'}';
      return Card(color:Colors.white,elevation:0,child:ListTile(leading:const Icon(Icons.receipt_long_outlined,color:green),title:Text(title),subtitle:Text(subtitle),trailing:SizedBox(width:115,child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text(money(amount),style:const TextStyle(color:green,fontWeight:FontWeight.bold,fontSize:12)),Text(state,style:const TextStyle(fontSize:10))]))));
    }));
  }
}
