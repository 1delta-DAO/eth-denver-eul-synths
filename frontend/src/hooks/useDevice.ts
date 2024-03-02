import { useMediaQuery } from "@chakra-ui/react";


const useDevice = () => {

  const mobileSize = "700px"
  const tabletMedium = "830px"
  const tabletSize = "1120px"

  const [isMobile] = useMediaQuery(`(max-width: ${mobileSize})`);
  const [isTabletMedium] = useMediaQuery(`(min-width: ${mobileSize}) and (max-width: ${tabletMedium})`);
  const [isTablet] = useMediaQuery(`(min-width: ${mobileSize}) and (max-width: ${tabletSize})`);

  return {
    isMobile,
    isTabletMedium,
    isTablet,
    isDesktop: !isMobile && !isTablet
  };

}

export default useDevice;
