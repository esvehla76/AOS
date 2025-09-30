//+------------------------------------------------------------------+
//| AOS_BollingerBands_EA.mq5                                        |
//| Expert Advisor implementing Bollinger Bands trading strategy      |
//| Author: Your Name                                                 |
//| Description:                                                      |
//| This EA will open a BUY position when the price breaks below the  |
//| lower Bollinger Band and returns to the zone. It will open a     |
//| SELL position when the price breaks above the upper Bollinger    |
//| Band and returns to the zone.                                    |
//+------------------------------------------------------------------+

input int BollingerPeriods = 14;    // Periods for Bollinger Bands
input double Deviation = 2.0;        // Deviation for Bollinger Bands
input ENUM_TIMEFRAMES TimeFrame = PERIOD_M15; // Timeframe
input double LotSize = 0.1;          // Lot size
input int MagicNumber = 123456;      // Magic number

double upperBand, middleBand, lowerBand;
bool inPosition = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit() {
    Print("Bollinger Bands EA initialized");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("Bollinger Bands EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Calculate Bollinger Bands
    upperBand = iBands(NULL, TimeFrame, BollingerPeriods, Deviation, 0, PRICE_CLOSE, 0);
    middleBand = iBands(NULL, TimeFrame, BollingerPeriods, Deviation, 0, PRICE_CLOSE, 1);
    lowerBand = iBands(NULL, TimeFrame, BollingerPeriods, Deviation, 0, PRICE_CLOSE, 2);

    // Check for SELL signal
    if (Close[1] > upperBand && Close[0] <= upperBand && !inPosition) {
        double tp = middleBand;
        double sl = tp - (tp - Close[0]) / 2;
        OrderSend(Symbol(), OP_SELL, LotSize, Bid, 2, sl, tp, "SELL Order", MagicNumber, 0, clrRed);
        inPosition = true;
    }

    // Check for BUY signal
    if (Close[1] < lowerBand && Close[0] >= lowerBand && !inPosition) {
        double tp = middleBand;
        double sl = tp + (Close[0] - tp) / 2;
        OrderSend(Symbol(), OP_BUY, LotSize, Ask, 2, sl, tp, "BUY Order", MagicNumber, 0, clrGreen);
        inPosition = true;
    }

    // Check if position is closed to reset inPosition
    if (OrdersTotal() == 0) {
        inPosition = false;
    }
}

//+------------------------------------------------------------------+
//| Custom function to handle order closing                           |
//+------------------------------------------------------------------+
void CloseOrder(int ticket) {
    if (OrderSelect(ticket, SELECT_BY_TICKET)) {
        if (OrderType() == OP_SELL) {
            OrderClose(ticket, OrderLots(), Bid, 2, clrRed);
        } else if (OrderType() == OP_BUY) {
            OrderClose(ticket, OrderLots(), Ask, 2, clrGreen);
        }
    }
}
//+------------------------------------------------------------------+