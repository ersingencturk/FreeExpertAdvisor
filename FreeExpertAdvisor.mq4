//+------------------------------------------------------------------+
//|                                            FreeExpertAdvisor.mq4 |
//|                                  Copyright 2017, Maxime Labelle. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Maxime Labelle."
#property link      "https://github.com/maxlabelle/FreeExpertAdvisor"
#property version   "1.00"
#property strict

enum AVAILABLE_SYMBOLS {
   EURCHF=1,
   USDCHF=2,
   AUDCHF=3,
   CADCHF=4,
   CHFJPY=5,
   GBPUSD=6,
   AUDUSD=7,
   GBPCHF=8
};

input string XXXXXXX1 = "[=============================================================]"; // ---
input string XXXXXXX2 = "FreeExpertAdvisor v1.0 "; // ---
input string XXXXXXX3 = "[=============================================================]"; // ---
input string XXXXXXX4 = "Money management settings";// ---
input string XXXXXXX5 = "[=============================================================]"; // ---
input double LotSize = 1.0; // Fixed lots size
input bool DynamicLots = FALSE; // Enable dynamic lots
input double LotSizeRisk = 15; // Dynamic Lots risk percentage
input int StopLoss = 500; // Hard stop loss in points
input string XXXXXXX6 = "[=============================================================]"; // ---
input string XXXXXXX7 = "EA Settings";// ---
input string XXXXXXX8 = "[=============================================================]"; // ---
input int Magic = 9516235; // Magic number
input int MaxSpread = 45; // Maximum spread, 0 for no limit
input int Slippage = 15; // Maximum slippage
input string XXXXXXX61 = "[=============================================================]"; // ---
input string XXXXXXX72 = "Chart Settings";// ---
input string XXXXXXX83 = "[=============================================================]"; // ---
input AVAILABLE_SYMBOLS SelectedSymbol = EURCHF; // Current chart symbol
input string XXXXXXX9 = "[=============================================================]"; // ---
input string XXXXXXX11 = "Time settings";// ---
input string XXXXXXX12 = "[=============================================================]"; // ---
input int GMTOffset = 2; // GMT Offset

bool RangingFilter = FALSE; // Enable Ranging filter
double ATR_TP_Multiplicator = 0.8; // ATR Take Profit multiplicator
double ATR_SL_Multiplicator = 3; // ATR Stop Loss multiplicator

bool StopTradingFriday = TRUE; // Stop trading on Friday
int FridayEndTime = 13; // End trading hour on Friday

double TAKE_PROFIT = 0;
double STOP_LOSS = 0;

int ThisBarTrade = 0;

static datetime time0;

double MyPoint=Point;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   if(Digits==3 || Digits==5) MyPoint=Point*10;
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

   // ==========================================================================================
   // Startup
   // ==========================================================================================

   if (!IsTesting()) {
      CreateInfoBox();
   }

   if (Period() != 5) {
      Print("FreeExpertAdvisor will only run when attached to the 5min chart");
      return;
   }

   bool newBar = (time0 < Time[0]);
   if (!newBar) return;

   int ORDERS_SELL = CountS();
   int ORDERS_BUY = CountB();

   if (ORDERS_BUY > 0 || ORDERS_SELL > 0) {
      bool newBar = (time0 < Time[1]);
      if (!newBar) return;
      //PerformVTP();
      PerformVTS();
   }

   if ( StopTradingFriday && DayOfWeek() == 5 ) {
      if (TimeFilter(0, FridayEndTime) == false) {
         return;
      }
   }

   if (MaxSpread > 0) {
      double CURRENT_SPREAD = MarketInfo(Symbol(), MODE_SPREAD);
      if (CURRENT_SPREAD > MaxSpread) {
         return;
      }
   }

   if (ORDERS_SELL != 0 || ORDERS_BUY != 0) {
      return;
   }

   // ==========================================================================================
   // Settings
   // ==========================================================================================

   bool STRATEGY_SPIKES = TRUE;
   bool STRATEGY_SPIKES_LONG = TRUE;
   bool STRATEGY_SPIKES_SHORT = TRUE;
   bool STRATEGY_SPIKES_TIMEFILTER = TRUE;
   double STRATEGY_SPIKES_RATIO_LONG = 3.5;
   double STRATEGY_SPIKES_RATIO_SHORT = 3.5;
   int STRATEGY_SPIKES_TIMEFILTER_TIMESTART = 0;
   int STRATEGY_SPIKES_TIMEFILTER_TIMEEND = 24;

   bool STRATEGY_CCI = TRUE;
   bool STRATEGY_CCI_LONG = TRUE;
   bool STRATEGY_CCI_SHORT = TRUE;
   bool STRATEGY_CCI_TIMEFILTER = TRUE;
   int STRATEGY_CCI_TIMEFILTER_TIMESTART = 0;
   int STRATEGY_CCI_TIMEFILTER_TIMEEND = 24;
   double STRATEGY_CCI_THRESHOLD_BUY = 250;
   double STRATEGY_CCI_THRESHOLD_SELL = 200;

   bool STRATEGY_LONGBARS = TRUE;
   bool STRATEGY_LONGBARS_LONG = TRUE;
   bool STRATEGY_LONGBARS_SHORT = TRUE;
   bool STRATEGY_LONGBARS_TIMEFILTER = TRUE;
   int STRATEGY_LONGBARS_TIMEFILTER_TIMESTART = 0;
   int STRATEGY_LONGBARS_TIMEFILTER_TIMEEND = 24;
   double STRATEGY_LONGBARS_RATIO_LONG = 3;
   double STRATEGY_LONGBARS_RATIO_SHORT = 3;

   /* ----------------------------
                EURCHF
      ---------------------------- */
   if (SelectedSymbol == 1) {
      STRATEGY_CCI_TIMEFILTER_TIMESTART = 19;
      STRATEGY_CCI_TIMEFILTER_TIMEEND = 4;

      STRATEGY_LONGBARS_TIMEFILTER_TIMESTART = 18;
      STRATEGY_LONGBARS_TIMEFILTER_TIMEEND = 3;

      STRATEGY_SPIKES_SHORT = FALSE;
      STRATEGY_SPIKES_TIMEFILTER = FALSE;

      STRATEGY_LONGBARS = TRUE;
      STRATEGY_SPIKES = TRUE;
      STRATEGY_CCI = TRUE;

      double ATR_VTS = iATR(Symbol(), Period(), 50, 0);
      TAKE_PROFIT = ATR_VTS * ATR_TP_Multiplicator;
      STOP_LOSS = ATR_VTS * ATR_SL_Multiplicator;
   }

   /* ----------------------------
                GBPCHF
      ---------------------------- */
   if (SelectedSymbol == 8) {
      STRATEGY_CCI_TIMEFILTER_TIMESTART = 19;
      STRATEGY_CCI_TIMEFILTER_TIMEEND = 4;

      STRATEGY_LONGBARS_TIMEFILTER_TIMESTART = 18;
      STRATEGY_LONGBARS_TIMEFILTER_TIMEEND = 3;

      //STRATEGY_SPIKES_SHORT = FALSE;
      STRATEGY_SPIKES_RATIO_SHORT = 4;
      STRATEGY_SPIKES_RATIO_LONG = 4;
      STRATEGY_SPIKES_TIMEFILTER = FALSE;

      STRATEGY_LONGBARS = TRUE;
      STRATEGY_SPIKES = TRUE;
      STRATEGY_CCI = TRUE;

      double ATR_VTS = iATR(Symbol(), Period(), 50, 0);
      TAKE_PROFIT = ATR_VTS * ATR_TP_Multiplicator;
      STOP_LOSS = ATR_VTS * ATR_SL_Multiplicator;
   }

   /* ----------------------------
                USDCHF
      ---------------------------- */
   if (SelectedSymbol == 2) {
      STRATEGY_CCI_TIMEFILTER_TIMESTART = 19;
      STRATEGY_CCI_TIMEFILTER_TIMEEND = 3;

      STRATEGY_LONGBARS_TIMEFILTER_TIMESTART = 18;
      STRATEGY_LONGBARS_TIMEFILTER_TIMEEND = 1;

      STRATEGY_SPIKES_TIMEFILTER = FALSE;
      STRATEGY_SPIKES_SHORT = FALSE;

      STRATEGY_LONGBARS = TRUE;
      STRATEGY_SPIKES = TRUE;
      STRATEGY_CCI = TRUE;

      double ATR_VTS = iATR(Symbol(), Period(), 50, 0);
      TAKE_PROFIT = ATR_VTS * ATR_TP_Multiplicator;
      STOP_LOSS = ATR_VTS * ATR_SL_Multiplicator;
   }

   /* ----------------------------
                GBPUSD
      ---------------------------- */
   if (SelectedSymbol == 6) {
      STRATEGY_LONGBARS = TRUE;
      STRATEGY_SPIKES = TRUE;
      STRATEGY_CCI = TRUE;

      STRATEGY_LONGBARS_SHORT = FALSE;
      STRATEGY_LONGBARS_TIMEFILTER_TIMESTART = 18;
      STRATEGY_LONGBARS_TIMEFILTER_TIMEEND = 0;
      STRATEGY_LONGBARS_RATIO_LONG = 2.5;

      STRATEGY_SPIKES_TIMEFILTER_TIMESTART = 3;
      STRATEGY_SPIKES_TIMEFILTER_TIMEEND = 6;

      STRATEGY_CCI_TIMEFILTER_TIMESTART = 3;
      STRATEGY_CCI_TIMEFILTER_TIMEEND = 6;

      STRATEGY_CCI_THRESHOLD_BUY = 300;
      STRATEGY_CCI_THRESHOLD_SELL = 300;

      double ATR_VTS = iATR(Symbol(), Period(), 50, 0);
      TAKE_PROFIT = ATR_VTS * ATR_TP_Multiplicator;
      STOP_LOSS = ATR_VTS * ATR_SL_Multiplicator;
   }

   // ==========================================================================================
   // Trading
   // ==========================================================================================



   // Spikes Strategy
   // ------------------------------------------------------------------------------------------
   if (STRATEGY_SPIKES) {
      double VolatilityRatioThresholdBuy = STRATEGY_SPIKES_RATIO_LONG; // Volatility ratio threshold for BUY
      double VolatilityRatioThresholdSell = STRATEGY_SPIKES_RATIO_SHORT; // Volatility ratio threshold for SELL

      double BBM_0 = iBands(Symbol(), PERIOD_M5, 20, 2.00, 0, PRICE_CLOSE, MODE_MAIN, 0);
      double BBU_0 = iBands(Symbol(), PERIOD_M5, 20, 2.00, 0, PRICE_CLOSE, MODE_UPPER, 0);
      double BBL_0 = iBands(Symbol(), PERIOD_M5, 20, 2.00, 0, PRICE_CLOSE, MODE_LOWER, 0);

      double range = MathMax(High[0],Close[1])-MathMin(Low[0],Close[1]);
      double atr = iATR(Symbol(),PERIOD_M5,14,1);
      double VR_0 = 0.0;

      if (atr!=0) {
         VR_0 = range/atr;
      }

      if (VR_0 > VolatilityRatioThresholdBuy && Ask < BBL_0) {
         bool open_buy = STRATEGY_SPIKES_LONG;

         if (STRATEGY_SPIKES_TIMEFILTER) {
            if (!TimeFilter(STRATEGY_SPIKES_TIMEFILTER_TIMESTART, STRATEGY_SPIKES_TIMEFILTER_TIMEEND)) {
               open_buy = FALSE;
            }
         }

         if (open_buy) {
            Buy();
         }
         return;
      }

      if (VR_0 > VolatilityRatioThresholdSell && Bid > BBU_0) {
         bool open_sell = STRATEGY_SPIKES_SHORT;

         if (STRATEGY_SPIKES_TIMEFILTER) {
            if (!TimeFilter(STRATEGY_SPIKES_TIMEFILTER_TIMESTART, STRATEGY_SPIKES_TIMEFILTER_TIMEEND)) {
               open_sell = FALSE;
            }
         }

         if (open_sell) {
            Sell();
         }
         return;
      }
   }

   // LongBars Strategy
   // ------------------------------------------------------------------------------------------
   if (STRATEGY_LONGBARS) {
      // M5
      double AVG_SIZE_PERIOD = 40; // Period for average bar size
      double AVG_SIZE_RATIO_LONG = STRATEGY_LONGBARS_RATIO_LONG; // Avg bar size ratio for LONG
      double AVG_SIZE_RATIO_SHORT = STRATEGY_LONGBARS_RATIO_SHORT; // Avg bar size ratio for SELL

      double BBM_0 = iBands(Symbol(), PERIOD_M5, 20, 2.00, 0, PRICE_CLOSE, MODE_MAIN, 0);
      double BBU_0 = iBands(Symbol(), PERIOD_M5, 20, 2.00, 0, PRICE_CLOSE, MODE_UPPER, 0);
      double BBL_0 = iBands(Symbol(), PERIOD_M5, 20, 2.00, 0, PRICE_CLOSE, MODE_LOWER, 0);

      double AVG_SIZE = 0.0;
      for ( int x = 1; x <= AVG_SIZE_PERIOD ; x++ ) {
         double SIZE = High[x] - Low[x];
         AVG_SIZE += SIZE;
      }

      AVG_SIZE = AVG_SIZE / AVG_SIZE_PERIOD;

      double CURRENT_SIZE = High[0] - Low[0];

      double CURRENT_RATIO = CURRENT_SIZE / AVG_SIZE;

      if (CURRENT_RATIO >= AVG_SIZE_RATIO_LONG && Ask < BBL_0) {
         bool open_buy = STRATEGY_LONGBARS_LONG;

         if (STRATEGY_LONGBARS_TIMEFILTER) {
            if (!TimeFilter(STRATEGY_LONGBARS_TIMEFILTER_TIMESTART, STRATEGY_LONGBARS_TIMEFILTER_TIMEEND)) {
               open_buy = FALSE;
            }
         }

         if (open_buy) {
            Buy();
         }
         return;
      }

      if (CURRENT_RATIO >= AVG_SIZE_RATIO_SHORT && Bid > BBU_0) {
         bool open_sell = STRATEGY_LONGBARS_SHORT;

         if (STRATEGY_LONGBARS_TIMEFILTER) {
            if (!TimeFilter(STRATEGY_LONGBARS_TIMEFILTER_TIMESTART, STRATEGY_LONGBARS_TIMEFILTER_TIMEEND)) {
               open_sell = FALSE;
            }
         }

         if (open_sell) {
            Sell();
         }
         return;
      }
   }

   // CCI Strategy
   // ------------------------------------------------------------------------------------------
   if (STRATEGY_CCI) {
      // M5

      double ATR_THRESHOLD = 2; // 3 == 344x - 91%, 2 == 766x 87%

      double ATR_0 = iATR(Symbol(), PERIOD_M5, 14, 0);

      double CCI_0 = iCCI(Symbol(), PERIOD_M5, 14, PRICE_CLOSE, 0);

      if (CCI_0 >= STRATEGY_CCI_THRESHOLD_SELL && ATR_0 >= (ATR_THRESHOLD * MyPoint)) {
         bool open_sell = STRATEGY_CCI_SHORT;

         if (STRATEGY_CCI_TIMEFILTER) {
            if (!TimeFilter(STRATEGY_CCI_TIMEFILTER_TIMESTART, STRATEGY_CCI_TIMEFILTER_TIMEEND)) {
               open_sell = FALSE;
            }
         }

         if (open_sell) {
            Sell();
         }
         return;
      }

      if (CCI_0 <= (STRATEGY_CCI_THRESHOLD_BUY * -1.0) && ATR_0 >= (ATR_THRESHOLD * MyPoint)) {
         bool open_buy = STRATEGY_CCI_LONG;

         if (STRATEGY_CCI_TIMEFILTER) {
            if (!TimeFilter(STRATEGY_CCI_TIMEFILTER_TIMESTART, STRATEGY_CCI_TIMEFILTER_TIMEEND)) {
               open_buy = FALSE;
            }
         }

         if (open_buy) {
            Buy();
         }
         return;
      }

      // M15
      CCI_0 = iCCI(Symbol(), PERIOD_M15, 14, PRICE_CLOSE, 0);

      if (CCI_0 >= STRATEGY_CCI_THRESHOLD_BUY && ATR_0 >= (ATR_THRESHOLD * MyPoint)) {
         bool open_sell = STRATEGY_CCI_SHORT;

         if (STRATEGY_CCI_TIMEFILTER) {
            if (!TimeFilter(STRATEGY_CCI_TIMEFILTER_TIMESTART, STRATEGY_CCI_TIMEFILTER_TIMEEND)) {
               open_sell = FALSE;
            }
         }

         if (open_sell) {
            Sell();
         }
         return;
      }

      if (CCI_0 <= (STRATEGY_CCI_THRESHOLD_BUY * -1.0) && ATR_0 >= (ATR_THRESHOLD * MyPoint)) {
         bool open_buy = STRATEGY_CCI_LONG;

         if (STRATEGY_CCI_TIMEFILTER) {
            if (!TimeFilter(STRATEGY_CCI_TIMEFILTER_TIMESTART, STRATEGY_CCI_TIMEFILTER_TIMEEND)) {
               open_buy = FALSE;
            }
         }

         if (open_buy) {
            Buy();
         }
         return;
      }
   }



}

void Sell() {
   double Lot=Lots();
   time0 = Time[0];
   double OpenPrice = Bid;
   double Loss = OpenPrice+(StopLoss*Point());
   int Sell = OrderSend(Symbol(),OP_SELL,Lot,OpenPrice,Slippage,Loss,0,"FreeExpertAdvisor",Magic,0,clrRed);

   if (Sell<0) {
      Print("OrderSend failed with error #",GetLastError());
   }
}

void Buy() {
   double Lot=Lots();
   time0 = Time[0];
   double OpenPrice = Ask;
   double Loss = OpenPrice-(StopLoss*Point());
   int Buy = OrderSend(Symbol(),OP_BUY,Lot,OpenPrice,Slippage,Loss,0,"FreeExpertAdvisor",Magic,0,clrAliceBlue);

   if (Buy<0) {
      Print("OrderSend failed with error #",GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Lot Size function                                                |
//+------------------------------------------------------------------+
double Lots() {
  double Lots = 0.01;

  if(DynamicLots == TRUE){
    Lots = NormalizeDouble(AccountEquity() * LotSizeRisk/100 / 1000.0, 2);
  }

  if(DynamicLots == FALSE) {
    Lots = LotSize;
  }

  double lotemin = MarketInfo(Symbol(), MODE_MINLOT);
  double lotemax = MarketInfo(Symbol(), MODE_MAXLOT);

  if (Lots > lotemax) { Lots = lotemax; }
  if (Lots < lotemin) { Lots = lotemin; }

  return Lots;
}

bool CheckMoneyForTrade(string symb, double lots,int type) {
   double free_margin=AccountFreeMarginCheck(symb,type, lots);
   //-- if there is not enough money
   if (free_margin<0) {
      string oper=(type==OP_BUY)? "Buy":"Sell";
      Print("Not enough money for ", oper," ",lots, " ", symb, " Error code=",GetLastError());
      return(false);
   }
   //--- checking successful
   return(true);
}

void PerformVTS() {

   double ATR_0 = iATR(Symbol(), Period(), 14, 0);

   for(int cnt=0; cnt<=OrdersTotal(); cnt++) {
      bool OS=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OS==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && (OrderType()==OP_BUY)) {
         if (Bid >= ( OrderOpenPrice() + TAKE_PROFIT )) {
         //if (Bid >= ( OrderOpenPrice() + ( BuyTakeProfit ))) {
            bool ordCls=OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Blue);
         }
         if (Bid <= (OrderOpenPrice() - STOP_LOSS )) {
         //if (Bid <= (OrderOpenPrice() - ( BuyStopLoss ))) {
            bool ordCls=OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Blue);


         }
      }
      if(OS==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && (OrderType()==OP_SELL)) {
         if (Ask <= ( OrderOpenPrice() - TAKE_PROFIT )) {
         //if (Ask <= ( OrderOpenPrice() - ( SellTakeProfit ) )) {
            bool ordCls=OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, Blue);
         }
         if (Ask >= (OrderOpenPrice() + STOP_LOSS )) {
         //if (Ask >= (OrderOpenPrice() + ( SellStopLoss ))) {
            bool ordCls=OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, Blue);


         }
      }
   }
}

//+------------------------------------------------------------------+
//| Count Buy Orders function                                        |
//+------------------------------------------------------------------+
int CountBS() {
   int i=0;
   for(int cnt=0; cnt<=OrdersTotal(); cnt++)
     {
      bool OS=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OS==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && (OrderType()==OP_BUYSTOP))
         i++;
     }
   return(i);
}

int CountB() {
   int i=0;
   for(int cnt=0; cnt<=OrdersTotal(); cnt++)
     {
      bool OS=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OS==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && (OrderType()==OP_BUY))
         i++;
     }
   return(i);
}
//+------------------------------------------------------------------+
//| Count Sell Orders function                                       |
//+------------------------------------------------------------------+
int CountS() {
   int i=0;
   for(int cnt=0; cnt<=OrdersTotal(); cnt++)
     {
      bool OS=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OS==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && (OrderType()==OP_SELL))
         i++;
     }
   return(i);
}
int CountSS() {
   int i=0;
   for(int cnt=0; cnt<=OrdersTotal(); cnt++)
     {
      bool OS=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OS==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && (OrderType()==OP_SELLSTOP))
         i++;
     }
   return(i);
}

bool TimeFilter(int start_time,int end_time) {
  int CurrentHour = TimeHour(TimeCurrent());

  start_time = start_time + ( GMTOffset );
  end_time = end_time + ( GMTOffset );

  if (start_time > end_time) {
     if (CurrentHour < start_time && CurrentHour >= end_time) {
      return false;
     } else {
      return true;
     }
  } else {
     if (CurrentHour >= start_time && CurrentHour < end_time) {
      return true;
     } else {
      return false;
     }
  }

}

void WriteText(string text, int Ydistance, int Xdistance = 10, int font_size = 10, color font_color = C'255,255,255', string font_name = "Tahoma") {
   string OBJNAME="SETXT_"+Ydistance;
   ObjectCreate(0,OBJNAME,OBJ_LABEL,0,Time[WindowFirstVisibleBar()-1],WindowPriceMax());
   ObjectSetString(0,OBJNAME,OBJPROP_FONT,font_name);
   ObjectSetString(0,OBJNAME,OBJPROP_TEXT,text);
   ObjectSetInteger(0,OBJNAME,OBJPROP_COLOR,font_color);
   ObjectSetInteger(0,OBJNAME,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(0,OBJNAME,OBJPROP_XDISTANCE,Xdistance);
   ObjectSetInteger(0,OBJNAME,OBJPROP_YDISTANCE,Ydistance);
}

int AnimationX = 10;
bool AnimationForward = true;

void CreateColorBox(color BoxColor, int Ydistance, int XDist = 0) {

   string OBJNAME="SEBOX_"+Ydistance+BoxColor;
   if (XDist == 0) {
      XDist = AnimationX;
   } else {
      OBJNAME="SEBOX_"+Ydistance+BoxColor+XDist;
   }

   ObjectDelete(OBJNAME);
   ObjectCreate(OBJNAME,OBJ_LABEL,0,0,0,0,0);
   ObjectSet(OBJNAME,OBJPROP_CORNER,0);
   ObjectSet(OBJNAME,OBJPROP_XDISTANCE,XDist);
   ObjectSet(OBJNAME,OBJPROP_YDISTANCE,Ydistance);
   ObjectSetText(OBJNAME,CharToStr(110),12,"Wingdings",BoxColor);
}

void CreateInfoBox() {
   string obj_name = "obj_rect";
   ObjectCreate(ChartID(),obj_name,OBJ_RECTANGLE_LABEL,0,0,0) ;
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_XDISTANCE,1);
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_YDISTANCE,1);
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_BGCOLOR,C'128,128,128');
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_COLOR,C'64,64,64');
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_XSIZE,300);
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_YSIZE,440);
   obj_name = "obj_rect_orange";
   ObjectCreate(ChartID(),obj_name,OBJ_RECTANGLE_LABEL,0,0,0) ;
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_XDISTANCE,50);
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_YDISTANCE,25);
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_WIDTH,0);
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_BGCOLOR,C'255,106,0');
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_COLOR,C'128,128,128');
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_XSIZE,200);
   ObjectSetInteger(ChartID(),obj_name,OBJPROP_YSIZE,100);

   WriteText("ExpertAdvisor", 45, 90, 16, C'64,64,64', "Arial Black");
   WriteText("Free", 80, 120, 16, C'64,64,64', "Arial Black");

   int ColorBoxYDistance = 330;
   CreateColorBox(LightGray, ColorBoxYDistance, 10);
   CreateColorBox(LightGray, ColorBoxYDistance, 20);
   CreateColorBox(LightGray, ColorBoxYDistance, 30);
   CreateColorBox(LightGray, ColorBoxYDistance, 40);
   CreateColorBox(LightGray, ColorBoxYDistance, 50);
   CreateColorBox(LightGray, ColorBoxYDistance, 60);
   CreateColorBox(LightGray, ColorBoxYDistance, 70);
   CreateColorBox(LightGray, ColorBoxYDistance, 80);
   CreateColorBox(LightGray, ColorBoxYDistance, 90);
   CreateColorBox(LightGray, ColorBoxYDistance, 100);
   CreateColorBox(LightGray, ColorBoxYDistance, 110);
   CreateColorBox(LightGray, ColorBoxYDistance, 120);
   CreateColorBox(LightGray, ColorBoxYDistance, 130);
   CreateColorBox(LightGray, ColorBoxYDistance, 140);
   CreateColorBox(LightGray, ColorBoxYDistance, 150);
   CreateColorBox(LightGray, ColorBoxYDistance, 160);
   CreateColorBox(LightGray, ColorBoxYDistance, 170);
   CreateColorBox(LightGray, ColorBoxYDistance, 180);
   CreateColorBox(LightGray, ColorBoxYDistance, 190);
   CreateColorBox(LightGray, ColorBoxYDistance, 200);
   CreateColorBox(LightGray, ColorBoxYDistance, 210);
   CreateColorBox(LightGray, ColorBoxYDistance, 220);
   CreateColorBox(LightGray, ColorBoxYDistance, 230);
   CreateColorBox(LightGray, ColorBoxYDistance, 240);
   CreateColorBox(LightGray, ColorBoxYDistance, 250);
   CreateColorBox(LightGray, ColorBoxYDistance, 260);
   CreateColorBox(LightGray, ColorBoxYDistance, 270);
   CreateColorBox(White, ColorBoxYDistance);
   if (AnimationX == 270) {
      AnimationForward = false;
   }
   if (AnimationX == 10) {
      AnimationForward = true;
   }

   if (AnimationForward) {
      AnimationX = AnimationX + 10;
   } else {
      AnimationX = AnimationX - 10;
   }

   WriteText("Broker: " + AccountCompany(), 150);
   WriteText("Server: " + AccountServer(), 170);
   WriteText("Account name: " + AccountName(), 190);
   WriteText("Account number: " + AccountNumber(), 210);
   WriteText("Account leverage: " + AccountLeverage() + ":1", 230);
   WriteText("Balance: " + NormalizeDouble(AccountBalance(),2), 250);
   WriteText("Equity: " + NormalizeDouble(AccountEquity(),2), 270);
   WriteText("Free margin: " + NormalizeDouble(AccountFreeMargin(),2), 290);
   WriteText("Profit: " + NormalizeDouble(AccountProfit(),2), 310);

   WriteText("Current symbol: " + Symbol(), 350);
   string txtSpread = MarketInfo(Symbol(), MODE_SPREAD);
   if (MaxSpread > 0) {
      txtSpread = txtSpread + " (max: "+MaxSpread+")";
   }
   WriteText("Current spread: " + txtSpread, 370);
   string dynLots = "Fixed";
   if (DynamicLots) {
      dynLots = "Dynamic";
   }
   WriteText("Type of lots: " + dynLots + " ("+NormalizeDouble(Lots(), 2)+")", 390);
   WriteText("Hard stop loss: " + StopLoss, 410);
}
