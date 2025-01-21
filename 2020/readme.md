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
- state循環: RST -> 3 -> 4 -> 1 -> 2 -> 3 ...
>總共需循環64次，並且64次後pattern一定由大排到小，因此只需要等到pattern由大排到小就知道已經將所有可能都數完了。
### 演算法實作
將每個worker要做的工作依序放在pattern裡，pivot為替換點，sub_pivot為比替換數大的最小數字。  
- pivot找法:  
在FIND_NEAR時從尾開始數，直到pattern[pivot] > pattern[pivot + 3'd1]時就會切至下一個state並且pivot也會固定住。直到COUNT_T時再將pivot重置。
- sub_pivot找法:  
  subpivot會先被設置成pivot，在FIND_MIN時從尾端開始找，若找到比subpivot小的數字則將subpivot改成它。
>先將subpivot設置成pivot可以保證在找subpivot過程不會因為找不到比subpivot原先小的數字而尋找失敗。
