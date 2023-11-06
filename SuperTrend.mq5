//+------------------------------------------------------------------+
//|                                                   SuperTrend.mq5 |
//|                                                         GivenM   |
//|                      https://github.com/gmakhobe/mql5-supertrend |
//+------------------------------------------------------------------+
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   2

#property indicator_label1  "SuperTrend"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrRed,clrGreen

//#property indicator_label2  "ColorBand"
//#property indicator_type2   DRAW_LINE
//#property indicator_color2  clrGreen

//-- Input Variables
input int      LookbackPeriod = 10;
input int      Multiplier = 3;

input ENUM_TIMEFRAMES ChartTimeframe = PERIOD_CURRENT;
//-- Global Varibles
int            ATRHandler;

datetime       PreviousTime;

const string   PairSymbol = Symbol();

bool           IsUpTrend = NULL;

//-- Buffers
double ATRBuffer[];
double SuperTrendLowerBand[];
double SuperTrendUpperBand[];
double FinalUpperBand[];
double FinalLowerBand[];
double SuperTrendIndicatorValue[];
double SuperTrendIndicatorColor[];
double SuperTrend[];

/*
   Initialize indicator
*/
int OnInit()
{
   ATRHandler = iATR(PairSymbol, ChartTimeframe, LookbackPeriod);

   if (ATRHandler == INVALID_HANDLE)
   {
      return (INIT_FAILED);
   }
 
   SetIndexBuffer(0, SuperTrendIndicatorValue, INDICATOR_DATA);
   SetIndexBuffer(1, SuperTrendIndicatorColor, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, SuperTrend, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, FinalUpperBand, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, FinalLowerBand, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, SuperTrendUpperBand, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, SuperTrendLowerBand, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, ATRBuffer, INDICATOR_CALCULATIONS);
   
   string shortname;
   StringConcatenate(shortname,"SuperTrend(",LookbackPeriod,")");
   //--- set a label do display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,shortname);   
   //--- set a name to show in a separate sub-window or a pop-up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
   //--- set accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,2);
   

   return(INIT_SUCCEEDED);
}

/*
   Perform calculations
*/
int OnCalculate(
   const int rates_total,
   const int prev_calculated,
   const datetime& time[],
   const double& open[],
   const double& high[],
   const double& low[],
   const double& close[],
   const long& tick_volume[],
   const long& volume[],
   const int& spread[])
{
   if (!CopyBuffer(ATRHandler, 0, 0, rates_total, ATRBuffer))
   {
      return rates_total;
   }
   
   //--- calculate values of mtm and |mtm|
   int start;

   if(prev_calculated == 0)
     {
      start = 2;  // start filling from the 1st index
      PreviousTime = time[0];
      FinalLowerBand[0] = 0;
      FinalUpperBand[0] = 0;
      SuperTrendIndicatorValue[0] = 0;
      SuperTrend[0] = 0;
      
      PreviousTime = time[1];
      FinalLowerBand[1] = 0;
      FinalUpperBand[1] = 0;
      SuperTrendIndicatorValue[1] = 0;
      SuperTrend[0] = 0;
     }
   else
     {
      start = prev_calculated - 1;
     }

   for(int i = start; i< rates_total; i++)
   {
      if (prev_calculated == 0 || PreviousTime != time[i])
      {
         SuperTrendUpperBand[i] = getBasicUpperBand(high[i], low[i], Multiplier, ATRBuffer[i]);
         SuperTrendLowerBand[i] = getBasicLowerBand(high[i], low[i], Multiplier, ATRBuffer[i]);
         FinalUpperBand[i] = getFinalUpperBand(SuperTrendUpperBand[i], FinalUpperBand[i - 1], close[i]);
         FinalLowerBand[i] = getFinalLowerBand(SuperTrendLowerBand[i], FinalLowerBand[i - 1], close[i]);
         
         if(FinalUpperBand[i] != 0 && FinalLowerBand[i] != 0 && FinalUpperBand[i - 1] != 0 && FinalLowerBand[i - 1] != 0)
         {
            if(close[i] > FinalUpperBand[i - 1])
            {
               IsUpTrend = true;
            }
            
            if(close[i] < FinalLowerBand[i - 1])
            {
               IsUpTrend = false;
            }
         }
         
         if (IsUpTrend == true)
         {
            SuperTrendIndicatorValue[i] = FinalLowerBand[i];
            SuperTrendIndicatorColor[i] = 1;
            SuperTrend[i] = 1;
         }
         
         if (IsUpTrend == false)
         {
            SuperTrendIndicatorValue[i] = FinalUpperBand[i];
            SuperTrendIndicatorColor[i] = 0;
            SuperTrend[i] = -1;
         }
         
         
         Print(SuperTrend[i - 1]);
         Print(SuperTrend[i]);
         
         PreviousTime = time[i];
      }
   }
   
  
   
   return rates_total;
}

/*
   Basic Upper Band
   Formula: BASIC UPPER BAND = HLA + [ MULTIPLIER * 10-DAY ATR ]
*/
/*
*  Function: getBasicUpperBand(
                     double _high,
                     double _low,
                     int _MULTIPLIER,
                     double _averageTrueRange)
*/
double getBasicUpperBand(
   double _high,
   double _low,
   int _MULTIPLIER,
   double _averageTrueRange)
  {
   double _highLowAverage = (_high + _low) / 2;
   double _basicBand = _highLowAverage + (_MULTIPLIER * _averageTrueRange);

   return _basicBand;
  }

/*
   Basic Lower Band
   Formula: BASIC LOWER BAND = HLA - [ MULTIPLIER * 10-DAY ATR ]
*/
/*
*  Function: getBasicLowerBand(
                     double _high,
                     double _low,
                     int _MULTIPLIER,
                     double _averageTrueRange)
*/
double getBasicLowerBand(
   double _high,
   double _low,
   int _MULTIPLIER,
   double _averageTrueRange)
  {
   double _highLowAverage = (_high + _low) / 2;
   double _basicBand = _highLowAverage - (_MULTIPLIER * _averageTrueRange);

   return _basicBand;
  }

/*
   Final Lowerband = If Current Basic Lowerband > Previous Final Lowerband OR
   Previous Close < Previous Final Lowerband Then Current Basic Lowerband Else Previous Final Lowerband
*/
/*
*  Function: getFinalLowerBand(double _currentbasicLowerBand,
                         double _previousFinalLowerBand,
                         double _previousClose)
*/
double getFinalLowerBand(double _currentbasicLowerBand,
                         double _previousFinalLowerBand,
                         double _previousClose)
  {
   double _currentBand;

   if(_currentbasicLowerBand > _previousFinalLowerBand ||
      _previousClose < _previousFinalLowerBand)
     {
      _currentBand = _currentbasicLowerBand;
     }
   else
     {
      _currentBand = _previousFinalLowerBand;
     }

   return _currentBand;
  }

// Get Final Upper Band
/*
   Final Upperband = If Current Basic Upperband < Previous Final Upperband OR
   Previous Close > Previous Final Upperband Then Current Basic Upperband Else Previous Final Upperband
*/
/*
*  Function: getFinalUpperBand(double _currentbasicUpperBand,
                         double _previousFinalUpperBand,
                         double _previousClose)
*/
double getFinalUpperBand(double _currentbasicUpperBand,
                         double _previousFinalUpperBand,
                         double _previousClose)
  {
   double _currentBand;

   if(_currentbasicUpperBand < _previousFinalUpperBand || _previousClose > _previousFinalUpperBand)
     {
      _currentBand = _currentbasicUpperBand;
     }
   else
     {
      _currentBand = _previousFinalUpperBand;
     }

   return _currentBand;
  }


