################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := cs-rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
ifneq ($(strip $(ASM_DEPS)),)
-include $(ASM_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
SECONDARY_FLASH += \
PH_Sudoku.hex \

SECONDARY_LIST += \
PH_Sudoku.lst \

SECONDARY_SIZE += \
PH_Sudoku.siz \


# All Target
all: PH_Sudoku.elf secondary-outputs

# Tool invocations
PH_Sudoku.elf: $(OBJS) $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: ARM Sourcery Windows GCC C Linker'
	arm-none-eabi-gcc -T"C:\Users\Jorge\Eclipse-Juno\PH_Sudoku\ld_script.ld" -nostartfiles -nostdlib -Wl,-Map,PH_Sudoku.map -mcpu=arm7tdmi -g3 -gdwarf-2 -o "PH_Sudoku.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

PH_Sudoku.hex: PH_Sudoku.elf
	@echo 'Invoking: ARM Sourcery Windows GNU Create Flash Image'
	arm-none-eabi-objcopy -O binary PH_Sudoku.elf  "PH_Sudoku.hex"
	@echo 'Finished building: $@'
	@echo ' '

PH_Sudoku.lst: PH_Sudoku.elf
	@echo 'Invoking: ARM Sourcery Windows GNU Create Listing'
	arm-none-eabi-objdump -h -S PH_Sudoku.elf > "PH_Sudoku.lst"
	@echo 'Finished building: $@'
	@echo ' '

PH_Sudoku.siz: PH_Sudoku.elf
	@echo 'Invoking: ARM Sourcery Windows GNU Print Size'
	arm-none-eabi-size  --format=berkeley PH_Sudoku.elf
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(SECONDARY_SIZE)$(OBJS)$(C_DEPS)$(ASM_DEPS)$(SECONDARY_FLASH)$(EXECUTABLES)$(SECONDARY_LIST)$(S_UPPER_DEPS) PH_Sudoku.elf
	-@echo ' '

secondary-outputs: $(SECONDARY_FLASH) $(SECONDARY_LIST) $(SECONDARY_SIZE)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
