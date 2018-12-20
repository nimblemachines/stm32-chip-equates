# We are trying to fix some really stupid, annoying, and confusing blunders by
# ST.

# First is to fix the CAN TypeDef so that the register names match what is in
# the reference manual and in the bit field definitions in the .h file.

#  CAN_TxMailBox_TypeDef      sTxMailBox[3];       /*!< CAN Tx MailBox,                      Address offset: 0x180 - 0x1AC */
/sTxMailBox/c\
  __IO uint32_t              TI0R;                /*!< CAN TX mailbox identifier register */\
  __IO uint32_t              TDT0R;               /*!< CAN mailbox data length control and time stamp register */\
  __IO uint32_t              TDL0R;               /*!< CAN mailbox data low register */\
  __IO uint32_t              TDH0R;               /*!< CAN mailbox data high register */\
  __IO uint32_t              TI1R;                /*!< CAN TX mailbox identifier register */\
  __IO uint32_t              TDT1R;               /*!< CAN mailbox data length control and time stamp register */\
  __IO uint32_t              TDL1R;               /*!< CAN mailbox data low register */\
  __IO uint32_t              TDH1R;               /*!< CAN mailbox data high register */\
  __IO uint32_t              TI2R;                /*!< CAN TX mailbox identifier register */\
  __IO uint32_t              TDT2R;               /*!< CAN mailbox data length control and time stamp register */\
  __IO uint32_t              TDL2R;               /*!< CAN mailbox data low register */\
  __IO uint32_t              TDH2R;               /*!< CAN mailbox data high register */

# CAN_FIFOMailBox_TypeDef    sFIFOMailBox[2];     /*!< CAN FIFO MailBox,                    Address offset: 0x1B0 - 0x1CC */
/sFIFOMailBox/c\
  __IO uint32_t              RI0R;                /*!< CAN receive FIFO mailbox identifier register */\
  __IO uint32_t              RDT0R;               /*!< CAN receive FIFO mailbox data length control and time stamp register */\
  __IO uint32_t              RDL0R;               /*!< CAN receive FIFO mailbox data low register */\
  __IO uint32_t              RDH0R;               /*!< CAN receive FIFO mailbox data high register */\
  __IO uint32_t              RI1R;                /*!< CAN receive FIFO mailbox identifier register */\
  __IO uint32_t              RDT1R;               /*!< CAN receive FIFO mailbox data length control and time stamp register */\
  __IO uint32_t              RDL1R;               /*!< CAN receive FIFO mailbox data low register */\
  __IO uint32_t              RDH1R;               /*!< CAN receive FIFO mailbox data high register */

# CAN_FilterRegister_TypeDef sFilterRegister[28]; /*!< CAN Filter Register,                 Address offset: 0x240-0x31C   */
# There are actually only 14 pairs of filter registers!!
/sFilterRegister/c\
  __IO uint32_t              F0R1;                /*!< CAN Filter bank 0 register 1 */\
  __IO uint32_t              F0R2;                /*!< CAN Filter bank 0 register 2 */\
  __IO uint32_t              F1R1;                /*!< CAN Filter bank 1 register 1 */\
  __IO uint32_t              F1R2;                /*!< CAN Filter bank 1 register 2 */\
  __IO uint32_t              F2R1;                /*!< CAN Filter bank 2 register 1 */\
  __IO uint32_t              F2R2;                /*!< CAN Filter bank 2 register 2 */\
  __IO uint32_t              F3R1;                /*!< CAN Filter bank 3 register 1 */\
  __IO uint32_t              F3R2;                /*!< CAN Filter bank 3 register 2 */\
  __IO uint32_t              F4R1;                /*!< CAN Filter bank 4 register 1 */\
  __IO uint32_t              F4R2;                /*!< CAN Filter bank 4 register 2 */\
  __IO uint32_t              F5R1;                /*!< CAN Filter bank 5 register 1 */\
  __IO uint32_t              F5R2;                /*!< CAN Filter bank 5 register 2 */\
  __IO uint32_t              F6R1;                /*!< CAN Filter bank 6 register 1 */\
  __IO uint32_t              F6R2;                /*!< CAN Filter bank 6 register 2 */\
  __IO uint32_t              F7R1;                /*!< CAN Filter bank 7 register 1 */\
  __IO uint32_t              F7R2;                /*!< CAN Filter bank 7 register 2 */\
  __IO uint32_t              F8R1;                /*!< CAN Filter bank 8 register 1 */\
  __IO uint32_t              F8R2;                /*!< CAN Filter bank 8 register 2 */\
  __IO uint32_t              F9R1;                /*!< CAN Filter bank 9 register 1 */\
  __IO uint32_t              F9R2;                /*!< CAN Filter bank 9 register 2 */\
  __IO uint32_t              F10R1;               /*!< CAN Filter bank 10 register 1 */\
  __IO uint32_t              F10R2;               /*!< CAN Filter bank 10 register 2 */\
  __IO uint32_t              F11R1;               /*!< CAN Filter bank 11 register 1 */\
  __IO uint32_t              F11R2;               /*!< CAN Filter bank 11 register 2 */\
  __IO uint32_t              F12R1;               /*!< CAN Filter bank 12 register 1 */\
  __IO uint32_t              F12R2;               /*!< CAN Filter bank 12 register 2 */\
  __IO uint32_t              F13R1;               /*!< CAN Filter bank 13 register 1 */\
  __IO uint32_t              F13R2;               /*!< CAN Filter bank 13 register 2 */

# Rename unused CAN sub-typedefs so we don't match them..

s/CAN_TxMailBox_TypeDef;/CAN_TxMailBox_IGNORE_TypeDef;/
s/CAN_FIFOMailBox_TypeDef;/CAN_FIFOMailBox_IGNORE_TypeDef;/
s/CAN_FilterRegister_TypeDef;/CAN_FilterRegister_IGNORE_TypeDef;/


# Next is the GPIO. AFR[2] is really AFRL and AFRH.
#  __IO uint32_t AFR[2];       /*!< GPIO alternate function registers,     Address offset: 0x20-0x24 */
/uint32_t AFR\[2\]/c\
  __IO uint32_t AFRL;         /*!< GPIO alternate function low register,  Address offset: 0x20 */\
  __IO uint32_t AFRH;         /*!< GPIO alternate function high register, Address offset: 0x24 */

# SYSCFG next.
#  __IO uint32_t EXTICR[4];   /*!< SYSCFG external interrupt configuration registers, Address offset: 0x14-0x08 */
/EXTICR\[4\]/c\
  __IO uint32_t EXTICR1;     /*!< SYSCFG external interrupt configuration register 1, Address offset: 0x08 */\
  __IO uint32_t EXTICR2;     /*!< SYSCFG external interrupt configuration register 2, Address offset: 0x0c */\
  __IO uint32_t EXTICR3;     /*!< SYSCFG external interrupt configuration register 3, Address offset: 0x10 */\
  __IO uint32_t EXTICR4;     /*!< SYSCFG external interrupt configuration register 4, Address offset: 0x14 */


# We're on a roll! How about the TSC?
#  __IO uint32_t IOGXCR[8];     /*!< TSC I/O group x counter register,                         Address offset: 0x34-50 */
/IOGXCR\[8\]/c\
  __IO uint32_t IOG1CR;        /*!< TSC I/O group 1 counter register,                         Address offset: 0x34 */\
  __IO uint32_t IOG2CR;        /*!< TSC I/O group 2 counter register,                         Address offset: 0x38 */\
  __IO uint32_t IOG3CR;        /*!< TSC I/O group 3 counter register,                         Address offset: 0x39 */\
  __IO uint32_t IOG4CR;        /*!< TSC I/O group 4 counter register,                         Address offset: 0x40 */\
  __IO uint32_t IOG5CR;        /*!< TSC I/O group 5 counter register,                         Address offset: 0x44 */\
  __IO uint32_t IOG6CR;        /*!< TSC I/O group 6 counter register,                         Address offset: 0x48 */\
  __IO uint32_t IOG7CR;        /*!< TSC I/O group 7 counter register,                         Address offset: 0x4c */\
  __IO uint32_t IOG8CR;        /*!< TSC I/O group 8 counter register,                         Address offset: 0x50 */


# Still TODO

# and what's up with the FSMC in the 407?
# also DIEPTXF array in the USB_OTG device in the 407?
# just realized that my Lua code won't match the USB_OTG stuff because it only
# matches <periph>_TypeDef", but the USB OTG stuff is all written
# <periph>TypeDef - in addition to *not* having any "instantiations" that
# create instances at fixed addresses. So I'll have to look at the reference
# manual to figure out what's going on.
