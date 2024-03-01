import React, { useState } from 'react';
import {
  Slider,
  SliderTrack,
  SliderFilledTrack,
  SliderThumb,
  SliderMark,
  Tooltip,
  SliderProps,
} from '@chakra-ui/react'

interface DecimalSliderProps extends SliderProps {
  tooltipSymbol?: string
  totalSliderMarks?: number
}

const DecimalSlider: React.FC<DecimalSliderProps> = ({ value, onChange, ...props }) => {

  const labelStyles = {
    mt: '-0.25rem',
    ml: '-0.25rem',
    bg: "black",
    p: '1',
    borderRadius: 'full',
  }

  const [showTooltip, setShowTooltip] = useState(false)

  const min = props.min ?? 0;
  const max = props.max ?? 100;

  const step = 
    !props.totalSliderMarks ?
      props.step ?? 25 :
      (max - min) / (props.totalSliderMarks - 1);

  const steps =
    !props.totalSliderMarks ?
      step != 0 ? (max - min) / step : 0 :
      props.totalSliderMarks - 1;

  return (
    <Slider
      id='slider'
      defaultValue={value}
      value={value}
      min={min}
      max={max}
      onChange={onChange}
      onMouseEnter={() => setShowTooltip(true)}
      onMouseLeave={() => setShowTooltip(false)}
      w="97%"
      margin="auto"
      step={5}
      {...props}
    >
      <SliderMark value={min} zIndex={1} {...labelStyles}/>
        {
          Array.from(Array(steps).keys()).map((_, index) => (
            <SliderMark key={index} value={min + (index + 1) * step} zIndex={1} {...labelStyles} />
          ))
        }
      <SliderMark value={max} zIndex={1} {...labelStyles} />
      <SliderTrack height="0.3rem" bgColor="#d9d9d9">
        <SliderFilledTrack bgColor="black" />
      </SliderTrack>
      <Tooltip
        hasArrow
        bg="black"
        color='white'
        placement='top'
        isOpen={showTooltip}
        label={`${value?.toLocaleString()}${props.tooltipSymbol ?? "%"}`}
      >
        <SliderThumb bg="black" />
      </Tooltip>
    </Slider>
  );
};

export default DecimalSlider;