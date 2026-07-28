/// 全局 store 单例（单窗口应用）。
library;

import 'accounts_store.dart';
import 'claim_store.dart';

final accountsStore = AccountsStore();
final claimStore = ClaimStore();
