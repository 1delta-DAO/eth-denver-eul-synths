import { HStack, VStack } from "@chakra-ui/react"
import DecimalSlider from "."

const SliderContainer = ({
  children,
  style
}: {
  children: React.ReactNode,
  style?: React.CSSProperties
}) => {
  return (
    <VStack
      w="100%"
      p="0.75rem"
      gap="0.75rem"
      borderRadius="0.5rem"
      style={style}
      background="white"
    >
      {children}
    </VStack>
  )
}

const MarginTag = ({
  children,
  style
}: {
  children: React.ReactNode,
  style?: React.CSSProperties
}) => {

  return (
    <HStack
      fontWeight={300}
      alignItems="center"
      justifyContent="flex-start"
      style={style}
    >
      {children}
    </HStack>
  )
}

interface LeverageSliderProps {
  maxLeverage: number
  value: number
  style?: React.CSSProperties
  tooltipSymbol?: string
  onChange: (value: number) => void;
}

const LeverageSlider: React.FC<LeverageSliderProps> = ({
  maxLeverage,
  value,
  style,
  tooltipSymbol,
  onChange,
}: LeverageSliderProps) => {

  const label = "Leverage"

  return (
    <SliderContainer style={style}>
      <DecimalSlider
        focusThumbOnChange={false}
        value={value}
        onChange={onChange}
        min={1}
        max={maxLeverage}
        step={0.1}
        totalSliderMarks={5}
        tooltipSymbol={tooltipSymbol}
      />
      <HStack
        w="100%"
        justifyContent="space-between"
      >
        <MarginTag style={{ gap: "0.3em", alignItems: "center" }}>
          <span style={{ lineHeight: "normal" }}>
            {label}
          </span>
        </MarginTag>
        <MarginTag style={{ lineHeight: "normal" }}>
          {
            maxLeverage > 0 &&
            <span>
              {value}x
            </span>
          }
        </MarginTag>
      </HStack>
    </SliderContainer>
  )
}

export default LeverageSlider