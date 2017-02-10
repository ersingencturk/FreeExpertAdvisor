# FreeExpertAdvisor

FreeExpertAdvisor is a free and open sourced Forex expert advisor for the Metatrader 4 platform

![FreeExpertAdvisor](http://i.imgur.com/qGxfBZR.png)

# About

It uses 3 different overbought/oversold based strategies.

It does not uses any martingale based strategy.

It is a scalper that only runs on the 5 minutes timeframe.

It has a 80% to 90% Win ratio on supported symbols

It uses a real stop loss and a virtual / invisible stop loss and take profit based on a multiplicator of the current ATR

It is FIFO compliant.

It opens only 1 position at a time.

# Supported Forex pairs

The following symbols are supported:

- EURCHF
- USDCHF
- GBPCHF
- AUDCHF
- JPYCHF
- CADCHF
- GBPUSD
- AUDUSD
- AUDCAD

It requires a low spread broker for the supported symbols with low commissions such as Tickmill, FXCM, Global Prime, Dukascopy, etc.

Note that the commission and/or the spread may reduce the expert advisor's profitability and overall viability.

# Settings

Fixed lots size : sizes of lots to use when dynamic lots is disabled

Enable dynamic lots : use a dynamic lot based on a percentage of current account balance

Dynamic Lots risk percentage : Percentage of the account's balance to risk, used in the calculation of the dynamic lot

Hard stop loss in points : Fixed stop loss in points for every position

GMT Offset : Set the broker's timezone GMT offset

Current chart symbol : Select the symbol for the attached chart

# Backtests

Symbol: EURCHF

Spread: 10

Starting balance: $10 000

Starting lots: 1.00

Dynamic lots: Enabled

Dynamic lots risk: 75.0%

![Backtesting EURCHF](http://i.imgur.com/UHlaDro.png)

![Backtesting EURCHF](http://i.imgur.com/REsqhWO.png)
