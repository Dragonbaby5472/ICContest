# Job Assignment Machine
演算法照題目所提供的字典序演算法
詳細演算法方法請請見題目

## 實作方法
### State Machine
分為四個狀態，分別為:
1. FIND_NEAR : 找尋替換點
2. FIND_MIN  : 找到比替換數大的最小數字，將之和替換數交換
3. FIND_TOTAL: 將所有需要的資料讀進JAM
4. COUNT_T   : 計算此pattern下的工作效率，並和之前結果做比較  
>總共需循環64次，並且64次後pattern一定由大排到小，因此只需要等到pattern由大排到小就知道已經將所有可能都數完了。
### 演算法實作

