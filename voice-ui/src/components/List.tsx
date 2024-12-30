import React, { useEffect, useState } from 'react';

interface ListProps {
    radioList: { id: string, Name: string, Talking?: boolean }[];
}

const List: React.FC<ListProps> = ({ radioList }) => {
    return (
        <div className="fixed top-[5%] right-[1%] text-right text-gray-pma font-bold text-shadow-black">
            <p className="text-[0.9rem] underline underline-offset-[0.2vw]">Radio list</p>
            <div className="flex flex-col gap-0 text-[0.8rem] mt-[0.2vw]">
                {Array.isArray(radioList) ? radioList.map((item, index) => (
                    <div key={index} className={`${item.Talking ? "text-gray-talking" : ""} transition-colors duration-300`}>{item.Name}</div>
                )) : null}
            </div>
        </div>
    );
};

export default List;