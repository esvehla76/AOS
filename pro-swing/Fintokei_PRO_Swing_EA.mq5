//+------------------------------------------------------------------+
//|                                        Fintokei_PRO_Swing_EA.mq5 |
//|                                  Copyright 2025, AOS Development |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AOS Development"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- Vstupní parametry
input group "=== Risk Management ==="
input double RiskPercent = 1.0;                    // Risk na obchod v %
input double MaxDailyDrawdownPercent = 5.0;        // Max denní drawdown %
input double MaxTotalDrawdownPercent = 10.0;       // Max celkový drawdown %

input group "=== Technické Indikátory ==="
input int EMA_Fast_Period = 21;                    // Rychlá EMA perioda
input int EMA_Slow_Period = 50;                    // Pomalá EMA perioda
input int RSI_Period = 14;                         // RSI perioda
input double RSI_Oversold = 30.0;                  // RSI oversold úroveň
input double RSI_Overbought = 70.0;                // RSI overbought úroveň

input group "=== ATR Nastavení ==="
input int ATR_Period = 14;                         // ATR perioda
input double ATR_Multiplier = 2.0;                 // ATR multiplikátor pro SL
input double ATR_TP_Ratio = 2.0;                   // Poměr TP:SL

input group "=== Obchodní Okna ==="
input int StartHour = 8;                           // Start obchodování (GMT)
input int EndHour = 18;                            // Konec obchodování (GMT)

input group "=== Ostatní ==="
input int MagicNumber = 12345;                     // Magic number pro identifikaci
input string TradeComment = "Fintokei_PRO_Swing"; // Komentář k pozicím

//--- Globální proměnné
double initialBalance;
double dailyStartBalance;
datetime lastDayCheck;
bool tradingBlocked = false;
int emaFastHandle, emaSlowHandle, rsiHandle, atrHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Inicializace balance
    initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    dailyStartBalance = initialBalance;
    lastDayCheck = TimeCurrent();
    
    // Vytvoření handlerů pro indikátory
    emaFastHandle = iMA(_Symbol, PERIOD_CURRENT, EMA_Fast_Period, 0, MODE_EMA, PRICE_CLOSE);
    emaSlowHandle = iMA(_Symbol, PERIOD_CURRENT, EMA_Slow_Period, 0, MODE_EMA, PRICE_CLOSE);
    rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
    atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
    
    // Kontrola handlerů
    if(emaFastHandle == INVALID_HANDLE || emaSlowHandle == INVALID_HANDLE || 
       rsiHandle == INVALID_HANDLE || atrHandle == INVALID_HANDLE)
    {
        Print("Chyba při vytváření handlerů indikátorů!");
        return(INIT_FAILED);
    }
    
    Print("Fintokei PRO Swing EA inicializován úspěšně");
    Print("Počáteční balance: ", DoubleToString(initialBalance, 2));
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Uvolnění handlerů
    IndicatorRelease(emaFastHandle);
    IndicatorRelease(emaSlowHandle);
    IndicatorRelease(rsiHandle);
    IndicatorRelease(atrHandle);
    
    Print("Fintokei PRO Swing EA ukončen");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Kontrola nového baru
    if(!IsNewBar())
        return;
        
    // Kontrola drawdownu a obchodních omezení
    CheckDrawdownLimits();
    
    if(tradingBlocked)
        return;
        
    // Kontrola obchodního času
    if(!IsTradingTime())
        return;
        
    // Kontrola existujících pozic
    if(HasOpenPosition())
        return;
        
    // Analýza signálů
    AnalyzeMarket();
}

//+------------------------------------------------------------------+
//| Kontrola nového baru                                            |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    
    if(lastBarTime != currentBarTime)
    {
        lastBarTime = currentBarTime;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Kontrola drawdown limitů                                        |
//+------------------------------------------------------------------+
void CheckDrawdownLimits()
{
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Reset denního drawdownu o půlnoci
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    datetime currentDay = StringToTime(StringFormat("%04d.%02d.%02d", timeStruct.year, timeStruct.mon, timeStruct.day));
    
    if(currentDay != lastDayCheck)
    {
        dailyStartBalance = currentBalance;
        lastDayCheck = currentDay;
        tradingBlocked = false; // Reset blokace na nový den
        Print("Nový obchodní den - reset denního drawdownu");
    }
    
    // Kontrola denního drawdownu
    double dailyDrawdown = (dailyStartBalance - currentEquity) / initialBalance * 100;
    if(dailyDrawdown >= MaxDailyDrawdownPercent)
    {
        tradingBlocked = true;
        Print("BLOKACE: Dosažen maximální denní drawdown: ", DoubleToString(dailyDrawdown, 2), "%");
        CloseAllPositions();
        return;
    }
    
    // Kontrola celkového drawdownu
    double totalDrawdown = (initialBalance - currentEquity) / initialBalance * 100;
    if(totalDrawdown >= MaxTotalDrawdownPercent)
    {
        tradingBlocked = true;
        Print("BLOKACE: Dosažen maximální celkový drawdown: ", DoubleToString(totalDrawdown, 2), "%");
        CloseAllPositions();
        return;
    }
}

//+------------------------------------------------------------------+
//| Kontrola obchodního času                                        |
//+------------------------------------------------------------------+
bool IsTradingTime()
{
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    
    return (timeStruct.hour >= StartHour && timeStruct.hour < EndHour);
}

//+------------------------------------------------------------------+
//| Kontrola existujících pozic                                     |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Analýza trhu a signálů                                          |
//+------------------------------------------------------------------+
void AnalyzeMarket()
{
    // Získání hodnot indikátorů
    double emaFast[], emaSlow[], rsi[], atr[];
    
    ArraySetAsSeries(emaFast, true);
    ArraySetAsSeries(emaSlow, true);
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(atr, true);
    
    if(CopyBuffer(emaFastHandle, 0, 0, 3, emaFast) < 3 ||
       CopyBuffer(emaSlowHandle, 0, 0, 3, emaSlow) < 3 ||
       CopyBuffer(rsiHandle, 0, 0, 3, rsi) < 3 ||
       CopyBuffer(atrHandle, 0, 0, 2, atr) < 2)
    {
        Print("Chyba při získávání dat indikátorů");
        return;
    }
    
    // Určení trendu pomocí EMA
    bool bullishTrend = (emaFast[0] > emaSlow[0] && emaFast[1] > emaSlow[1]);
    bool bearishTrend = (emaFast[0] < emaSlow[0] && emaFast[1] < emaSlow[1]);
    
    // Signály pro nákup (bullish pullback)
    if(bullishTrend && rsi[0] <= RSI_Oversold && rsi[1] > RSI_Oversold)
    {
        OpenPosition(ORDER_TYPE_BUY, atr[0]);
    }
    
    // Signály pro prodej (bearish pullback)
    if(bearishTrend && rsi[0] >= RSI_Overbought && rsi[1] < RSI_Overbought)
    {
        OpenPosition(ORDER_TYPE_SELL, atr[0]);
    }
}

//+------------------------------------------------------------------+
//| Otevření pozice                                                  |
//+------------------------------------------------------------------+
void OpenPosition(ENUM_ORDER_TYPE orderType, double atrValue)
{
    double price, sl, tp;
    double lotSize = CalculateLotSize(atrValue);
    
    if(lotSize == 0)
    {
        Print("Chyba při kalkulaci velikosti pozice");
        return;
    }
    
    // Nastavení ceny a SL/TP
    if(orderType == ORDER_TYPE_BUY)
    {
        price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        sl = price - (atrValue * ATR_Multiplier);
        tp = price + (atrValue * ATR_Multiplier * ATR_TP_Ratio);
    }
    else
    {
        price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        sl = price + (atrValue * ATR_Multiplier);
        tp = price - (atrValue * ATR_Multiplier * ATR_TP_Ratio);
    }
    
    // Normalizace hodnot
    price = NormalizeDouble(price, _Digits);
    sl = NormalizeDouble(sl, _Digits);
    tp = NormalizeDouble(tp, _Digits);
    
    // Vytvoření objednávky
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lotSize;
    request.type = orderType;
    request.price = price;
    request.sl = sl;
    request.tp = tp;
    request.magic = MagicNumber;
    request.comment = TradeComment;
    request.deviation = 10;
    
    bool orderResult = OrderSend(request, result);
    if(orderResult && result.retcode == TRADE_RETCODE_DONE)
    {
        Print("Pozice otevřena úspěšně: ", EnumToString(orderType), 
              " Lot: ", DoubleToString(lotSize, 2),
              " Cena: ", DoubleToString(price, _Digits),
              " SL: ", DoubleToString(sl, _Digits),
              " TP: ", DoubleToString(tp, _Digits));
    }
    else
    {
        Print("Chyba při otevírání pozice: ", result.retcode, " - ", result.comment);
    }
}

//+------------------------------------------------------------------+
//| Kalkulace velikosti pozice na základě ATR                       |
//+------------------------------------------------------------------+
double CalculateLotSize(double atrValue)
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * RiskPercent / 100.0;
    double stopLossPoints = atrValue * ATR_Multiplier;
    
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double pointValue = tickValue * tickSize / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    double lotSize = riskAmount / (stopLossPoints * pointValue);
    
    // Kontrola minimální a maximální velikosti lotu
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Uzavření všech pozic                                            |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
                MqlTradeRequest request = {};
                MqlTradeResult result = {};
                
                request.action = TRADE_ACTION_DEAL;
                request.symbol = _Symbol;
                request.volume = PositionGetDouble(POSITION_VOLUME);
                request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
                request.price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                               SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                request.magic = MagicNumber;
                request.comment = "Emergency Close";
                request.deviation = 10;
                
                bool closeResult = OrderSend(request, result);
                if(!closeResult || result.retcode != TRADE_RETCODE_DONE)
                {
                    Print("Chyba při uzavírání pozice: ", result.retcode, " - ", result.comment);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Obsluha obchodních událostí                                     |
//+------------------------------------------------------------------+
void OnTrade()
{
    // Zde můžete přidat logiku pro reakci na obchodní události
    // například trailing stop, částečné uzavírání pozic, atd.
}

//+------------------------------------------------------------------+